defmodule PrivCheck.IntegrationPhoenixUmbrellaTest do
  use ExUnit.Case, async: true

  setup_all do
    mix!("brella_demo_umbrella", ~w/deps.get/)

    :ok
  end

  setup do
    mix!("brella_demo_umbrella", ~w/clean/)

    :ok
  end

  test "reports expected warnings for" do
    {output, _code} = mix("brella_demo_umbrella", ~w/compile/)

    warnings = warnings(output)

    assert Enum.member?(warnings, %{
             location: "lib/brella_demo_web/controllers/page_controller.ex:7",
             warning:
               "Elixir.BrellaDemo.NonPublic is not a public module and should not be referenced from other applications."
           })

    assert Enum.member?(warnings, %{
             location: "lib/brella_demo_web/controllers/page_controller.ex:7",
             warning:
               "BrellaDemo.NonPublic.a_function/0 is not a public function and should not be called from other applications. Called from: BrellaDemoWeb.PageController."
           })

    assert length(warnings) == 2
  end

  test "exit code is zero with default options" do
    {_output, code} = mix("brella_demo_umbrella", ~w/compile/)
    assert code == 0
  end

  test "exit code is non-zero with --warnings-as-errors" do
    {_output, code} = mix("brella_demo_umbrella", ~w/compile --warnings-as-errors/)
    assert code == 1
  end

  defp mix!(project_name, args) do
    {output, 0} = mix(project_name, args)
    output
  end

  defp mix(project_name, args),
    do: System.cmd("mix", args, stderr_to_stdout: true, cd: Path.join(~w/demos #{project_name}/))

  defp warnings(output) do
    output
    |> String.split(~r/\n|\r/)
    |> Stream.map(&String.trim/1)
    |> Stream.chunk_every(4, 1)
    |> Stream.filter(&match?("warning: " <> _, hd(&1)))
    |> Enum.map(fn ["warning: " <> warning, line_2, line_3, line_4] ->
      if(String.starts_with?(line_2, "("),
        do: %{explanation: line_2, callee: line_3, location: line_4},
        else: %{location: line_2}
      )
      |> Map.put(:warning, String.trim(warning))
    end)
  end
end
