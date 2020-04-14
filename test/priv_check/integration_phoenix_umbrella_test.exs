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
    |> Enum.to_list()
    |> Enum.map(fn
      ["warning: " <> warning, line2, line3, ""] ->
        warning_text =
          [warning, line2]
          |> Enum.map(&String.trim/1)
          |> Enum.join(" ")

        %{
          warning: warning_text,
          location: line3
        }

      ["warning: " <> warning, line2, line3, line4] ->
        warning_text =
          [warning, line2, line3]
          |> Enum.map(&String.trim/1)
          |> Enum.join(" ")

        %{
          warning: warning_text,
          location: line4
        }
    end)
  end
end
