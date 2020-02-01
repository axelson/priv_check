defmodule PrivCheckExampleTest do
  use ExUnit.Case
  doctest PrivCheckExample

  test "greets the world" do
    assert PrivCheckExample.hello() == :world
  end
end
