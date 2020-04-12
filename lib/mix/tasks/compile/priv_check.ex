defmodule Mix.Tasks.Compile.PrivCheck do
  @moduledoc """
  Compiler that checks for calls to code that is marked as private, typically
  via `@moduledoc false` and `@doc false`.

  This module is responsible for running the compiler and formatting warnings
  """

  use Mix.Task.Compiler

  @recursive true

  @tracer_module PrivCheck.Tracer

  @impl Mix.Task.Compiler
  def run(argv) do
    _ = PrivCheck.Tracer.start_link([])
    _ = PrivCheck.TracesManifest.start_link()

    Mix.Task.Compiler.after_compiler(:app, &after_compiler(&1, argv))
    tracers = Code.get_compiler_option(:tracers)
    Code.put_compiler_option(:tracers, [@tracer_module | tracers])

    {:ok, []}
  end

  defp after_compiler({:error, _} = status, _), do: status

  defp after_compiler({status_code, existing_diagnostics}, argv)
       when status_code in [:ok, :noop] do
    # Remove the tracer because we're done with it
    tracers = Enum.reject(Code.get_compiler_option(:tracers), &(&1 == @tracer_module))
    Code.put_compiler_option(:tracers, tracers)
    PrivCheck.TracesManifest.flush([])

    PrivCheck.Mix.load_app()
    app_modules = MapSet.new(app_modules())
    traces = PrivCheck.TracesManifest.traces()

    diagnostics =
      PrivCheck.ReferenceChecker.diagnostics(traces, app_modules)
      # Sort the diagnostics for readability (sort by file first then by line
      # number in the file)
      |> Enum.sort_by(fn diagnostic -> {diagnostic.file, diagnostic.position} end)

    print_diagnostics(diagnostics)

    {status(diagnostics, argv), Enum.concat(diagnostics, existing_diagnostics)}
  end

  def print_diagnostics(diagnostics) do
    print_diagnostic_errors(diagnostics)
  end

  defp app_modules do
    app = PrivCheck.Mix.app_name()
    Application.load(app)
    Application.spec(app, :modules)
  end

  defp status(diagnostics, argv)
  defp status([], _), do: :ok
  defp status([_ | _], argv), do: if(warnings_as_errors?(argv), do: :error, else: :ok)

  defp warnings_as_errors?(argv) do
    {parsed, _argv, _errors} = OptionParser.parse(argv, strict: [warnings_as_errors: :boolean])
    Keyword.get(parsed, :warnings_as_errors, false)
  end

  defp print_diagnostic_errors(errors) do
    if errors != [], do: IO.puts("")
    Enum.each(errors, &print_diagnostic_error/1)
  end

  defp print_diagnostic_error(error) do
    Mix.shell().info([severity(error.severity), error.message, location(error)])
  end

  defp location(error) do
    if error.file != nil and error.file != "" do
      pos = if error.position != nil, do: ":#{error.position}", else: ""
      "\n  #{error.file}#{pos}\n"
    else
      "\n"
    end
  end

  defp severity(severity), do: [:bright, color(severity), "#{severity}: ", :reset]
  defp color(:error), do: :red
  defp color(:warning), do: :yellow
end
