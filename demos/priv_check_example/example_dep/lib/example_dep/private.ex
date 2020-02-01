# Completely private dependency
defmodule ExampleDep.Private do
  @moduledoc false

  def add(a, b) do
    a + b
  end

  @doc "has a doc, but it shouldn't be accessible"
  def with_doc do
    42
  end
end
