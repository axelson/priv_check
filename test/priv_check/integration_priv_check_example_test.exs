defmodule PrivCheck.IntegrationPrivCheckExampleTest do
  use ExUnit.Case, async: true

  setup_all do
    mix!("priv_check_example", ~w/deps.get/)

    :ok
  end

  setup do
    mix!("priv_check_example", ~w/clean/)

    :ok
  end

  test "reports expected warnings" do
    {output, _code} = mix("priv_check_example", ~w/compile/)

    warnings = warnings(output)

    assert Enum.member?(warnings, %{
             location: "lib/priv_check_example.ex:17",
             warning:
               "Elixir.ExampleDep.Private is not a public module and should not be referenced from other applications."
           })

    assert Enum.member?(warnings, %{
             location: "lib/priv_check_example.ex:20",
             warning:
               "ExampleDep.Mixed.private/0 is not a public function and should not be called from other applications. Called from: PrivCheckExample."
           })

    assert Enum.member?(warnings, %{
             location: "lib/priv_check_example.ex:21",
             warning:
               "Elixir.ExampleDep.Private is not a public module and should not be referenced from other applications."
           })

    assert Enum.member?(warnings, %{
             location: "lib/priv_check_example.ex:21",
             warning:
               "ExampleDep.Private.add/2 is not a public function and should not be called from other applications. Called from: PrivCheckExample."
           })

    assert Enum.member?(warnings, %{
             location: "lib/priv_check_example.ex:22",
             warning:
               "Elixir.ExampleDep.Private is not a public module and should not be referenced from other applications."
           })

    assert Enum.member?(warnings, %{
             location: "lib/priv_check_example.ex:22",
             warning:
               "ExampleDep.Private.with_doc/0 is not a public function and should not be called from other applications. Called from: PrivCheckExample."
           })

    assert length(warnings) == 6
  end

  test "exit code is zero with default options" do
    {_output, code} = mix("priv_check_example", ~w/compile/)
    assert code == 0
  end

  test "exit code is non-zero with --warnings-as-errors" do
    {_output, code} = mix("priv_check_example", ~w/compile --warnings-as-errors/)
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
