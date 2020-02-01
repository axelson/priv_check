defmodule ExampleDepTest do
  use ExUnit.Case
  doctest ExampleDep

  test "greets the world" do
    assert ExampleDep.hello() == :world
  end
end
