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
    PrivCheckExample.Private.add(1, 2)

    # Expected not to be caught
    ExampleDep.PubMacros.expand_priv()

    # Cannot be detected
    mod = String.to_atom("Elixir.ExampleDep.Private")
    mod.add(1, 2)

    :ok
  end
end
