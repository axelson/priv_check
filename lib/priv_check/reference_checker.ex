# Checks if a traced reference (alias_reference or remtoe_function call) was
# to a private module or function, building mix diagnotic errors if so
defmodule PrivCheck.ReferenceChecker do
  @moduledoc false

  def diagnostics(traces, app_modules) do
    %PrivCheck.Tracer.State{
      alias_references: alias_references,
      remote_function_calls: remote_function_calls,
      remote_macro_calls: remote_macro_calls
    } = traces

    macro_calls = build_public_macro_calls_map(remote_macro_calls, app_modules)

    (reference_errors(alias_references, app_modules) ++
       remote_function_call_errors(remote_function_calls, app_modules))
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
    for {{mod, _fun, _arity} = mfa, file, line} <- remote_macro_calls,
        !MapSet.member?(app_modules, mod),
        PrivCheck.DocChecker.public_fun?(mfa),
        into: %{} do
      {{Path.relative_to_cwd(file), line}, mfa}
    end
  end

  @spec remote_function_call_errors([PrivCheck.Tracer.remote_function_call()], any) :: [
          Mix.Task.Compiler.Diagnostic.t()
        ]
  def remote_function_call_errors(remote_function_calls, app_modules) do
    for {{mod, fun, arity} = mfa, called_from_module, file, line} <- remote_function_calls,
        !in_macro_generated_func(called_from_module, file, line),
        !MapSet.member?(app_modules, mod),
        into: [] do
      if PrivCheck.DocChecker.public_fun?(mfa) do
        nil
      else
        message =
          "#{inspect(mod)}.#{fun}/#{arity} is not a public function and should not be " <>
            "called from other applications."

        diagnostic_error(message, nil, file: Path.relative_to_cwd(file), position: line)
      end
    end
  end

  @spec reference_errors([PrivCheck.Tracer.alias_reference()], any) :: [
          Mix.Task.Compiler.Diagnostic.t()
        ]
  def reference_errors(alias_references, app_modules) do
    for {referenced_module, file, line, defined_in_module} <- alias_references,
        !MapSet.member?(app_modules, referenced_module),
        !in_macro_generated_func(defined_in_module, file, line),
        into: [] do
      case PrivCheck.DocChecker.mod_visibility(referenced_module) do
        :public ->
          nil

        :private ->
          message =
            "#{referenced_module} is not a public module and should not be referenced " <>
              "from other applications."

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
