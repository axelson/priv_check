defmodule PrivCheck.ReferenceChecker do
  @moduledoc false

  # Checks if a traced reference (alias_reference or remtoe_function call) was
  # to a private module or function, building mix diagnotic errors if so

  def diagnostics(traces, app_modules) do
    %PrivCheck.Tracer.State{
      alias_references: alias_references,
      remote_function_calls: remote_function_calls,
      remote_macro_calls: remote_macro_calls
    } = traces

    # IO.inspect(remote_macro_calls, label: "remote_macro_calls")
    macro_calls = build_public_macro_calls_map(remote_macro_calls, app_modules)
    IO.inspect(macro_calls, label: "macro_calls")

    (reference_errors(alias_references, app_modules) ++
       remote_function_call_errors(remote_function_calls, app_modules))
    |> Enum.reject(&(&1 == nil))
    |> Enum.reject(&maybe_generated_code?(&1, macro_calls))
    |> IO.inspect(label: "diag")
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
      {{file, line}, mfa}
      |> IO.inspect(label: "inserting")
    end
  end

  @spec remote_function_call_errors([PrivCheck.Tracer.remote_function_call()], any) :: [
          Mix.Task.Compiler.Diagnostic.t()
        ]
  def remote_function_call_errors(remote_function_calls, app_modules) do
    for {{mod, fun, arity} = mfa, file, line} <- remote_function_calls,
        !MapSet.member?(app_modules, mod),
        into: [] do
      case PrivCheck.DocChecker.mfa_visibility(mfa) do
        :public ->
          nil

        :private ->
          message =
            "#{inspect(mod)}.#{fun}/#{arity} is not a public function and should not be " <>
              "called other applications."

          diagnostic_error(message, file: file, position: line)

        _ ->
          # TODO: remove this catch-all
          nil
      end
    end
  end

  @spec reference_errors([PrivCheck.Tracer.alias_reference()], any) :: [
          Mix.Task.Compiler.Diagnostic.t()
        ]
  def reference_errors(alias_references, app_modules) do
    for {referenced_module, file, line} <- alias_references,
        !MapSet.member?(app_modules, referenced_module),
        into: [] do
      case PrivCheck.DocChecker.mod_visibility(referenced_module) do
        :public ->
          nil

        :private ->
          message =
            "#{referenced_module} is not a public module and should not be referenced " <>
              "from other applications."

          diagnostic_error(message,
            file: file,
            position: line
          )

        :not_found ->
          nil
      end
    end
  end

  def diagnostic_error(message, opts \\ []) do
    %Mix.Task.Compiler.Diagnostic{
      compiler_name: "boundary",
      details: nil,
      file: "unknown",
      message: message,
      position: nil,
      severity: :warning
    }
    |> Map.merge(Map.new(opts))
  end
end
