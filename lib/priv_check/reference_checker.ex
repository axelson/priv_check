# Checks if a traced reference (alias_reference or remtoe_function call) was
# to a private module or function, building mix diagnotic errors if so
defmodule PrivCheck.ReferenceChecker do
  @moduledoc false

  def diagnostics(traces, app_modules) do
    %PrivCheck.TracesManifest.Traces{
      alias_references: alias_references,
      remote_function_calls: remote_function_calls,
      remote_macro_calls: remote_macro_calls
    } = traces

    config = PrivCheck.Config.from_file_system()

    macro_calls = build_public_macro_calls_map(remote_macro_calls, app_modules)

    (reference_errors(alias_references, app_modules, config) ++
       remote_function_call_errors(remote_function_calls, app_modules, config))
    |> Enum.reject(&(&1 == nil))
    |> Enum.reject(&maybe_generated_code?(&1, macro_calls))
  end

  defp maybe_generated_code?(diagnostic, macro_calls) do
    case Map.get(macro_calls, {diagnostic.file, diagnostic.position}) do
      nil -> false
      _ -> true
    end
  end

  def build_public_macro_calls_map(remote_macro_calls, app_modules) do
    for {{mod, _fun, _arity} = mfa, _caller, file, line} <- remote_macro_calls,
        # Ignore calls into the current application
        !MapSet.member?(app_modules, mod),
        PrivCheck.DocChecker.public_fun?(mfa),
        into: %{} do
      {{Path.relative_to_cwd(file), line}, mfa}
    end
  end

  @spec remote_function_call_errors([PrivCheck.Tracer.remote_function_call()], any, any) :: [
          Mix.Task.Compiler.Diagnostic.t()
        ]
  def remote_function_call_errors(remote_function_calls, app_modules, config) do
    for {{mod, fun, arity} = mfa, called_from_module, file, line} <- remote_function_calls,
        !in_macro_generated_func(called_from_module, file, line),
        !user_config_ignored?(file, mod, config),
        !MapSet.member?(app_modules, mod),
        into: [] do
      if PrivCheck.DocChecker.public_fun?(mfa) do
        nil
      else
        message =
          "#{inspect(mod)}.#{fun}/#{arity} is not a public function\n" <>
            "  and should not be called from other applications.\n" <>
            "  Called from: #{inspect(called_from_module)}."

        diagnostic_error(message, nil, file: Path.relative_to_cwd(file), position: line)
      end
    end
  end

  def user_config_ignored?(file, called_module, config) do
    alias PrivCheck.Config
    path = Path.relative_to_cwd(file)

    Config.ignore_calls_from_file(config, path) ||
      Config.ignore_references_to_module(config, called_module)
  end

  @spec reference_errors([PrivCheck.Tracer.alias_reference()], any, any) :: [
          Mix.Task.Compiler.Diagnostic.t()
        ]
  def reference_errors(alias_references, app_modules, config) do
    for {referenced_module, file, line, defined_in_module} <- alias_references,
        !MapSet.member?(app_modules, referenced_module),
        !user_config_ignored?(file, referenced_module, config),
        !in_macro_generated_func(defined_in_module, file, line),
        into: [] do
      case PrivCheck.DocChecker.mod_visibility(referenced_module) do
        :public ->
          nil

        :private ->
          message =
            "#{referenced_module} is not a public module\n" <>
              "  and should not be referenced from other applications."

          diagnostic_error(
            message,
            nil,
            file: Path.relative_to_cwd(file),
            position: line
          )

        :not_found ->
          nil
      end
    end
  end

  # Ignore warnings from code generated with macros with `location: :keep`
  # These are detected because the source file location does not match the
  # source file that it was called from
  defp in_macro_generated_func(nil, _file, _line), do: false

  defp in_macro_generated_func(module, file, _line) do
    case module.module_info(:compile)[:source] do
      nil -> true
      path -> !String.contains?(file, to_string(path))
    end
  end

  def diagnostic_error(message, details, opts \\ []) do
    %Mix.Task.Compiler.Diagnostic{
      compiler_name: "priv_check",
      details: details,
      file: "unknown",
      message: message,
      position: nil,
      severity: :warning
    }
    |> Map.merge(Map.new(opts))
  end
end
