defmodule PrivCheck.Test.ExamplePublicModule do
  @moduledoc "A public module"

  @doc "public func"
  def publicly_documented_func do
  end

  def non_documented_func do
  end

  def non_documented_func(_) do
  end

  @doc false
  def doc_false_func do
  end
end
