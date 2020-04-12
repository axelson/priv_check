defmodule PrivCheckExample do
  @moduledoc """
  Documentation for PrivCheckExample.
  """

  require Logger
  require ExampleDep.PubMacros

  def example do
    # Should not generate a warning
    Logger.info("hello world")
    ExampleDep.Mixed.public()
    ExampleDep.Mixed.no_doc_public()

    # Should generate warnings

    mod = ExampleDep.Private
    IO.inspect(mod, label: "mod")

    ExampleDep.Mixed.private()
    ExampleDep.Private.add(1, 2)
    ExampleDep.Private.with_doc()
    # Same application so no warning
    PrivCheckExample.Private.add(1, 2)

    # Expected be ignored
    ExampleDep.PubMacros.expand_priv()

    # Cannot be detected
    mod = String.to_atom("Elixir.ExampleDep.Private")
    mod.add(1, 2)

    Mix.Tasks.Xref.__info__(:functions)

    :ok
  end

  ExampleDep.PubMacros.expand_funcs()

  def other(num) do
    if num == 5 do
      raise "Boom"
    else
      num + 1
    end
  end
end
