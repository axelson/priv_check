defmodule PrivCheckExample.Private do
  @moduledoc false

  # This is a module that is private but is in the same project

  def add(a, b), do: a + b
end
