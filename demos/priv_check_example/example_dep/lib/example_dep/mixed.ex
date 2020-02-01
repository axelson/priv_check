defmodule ExampleDep.Mixed do
  @moduledoc """
  Public module but has a public function and a "private" function
  """

  @doc "fully public"
  def public do
    42
  end

  def no_doc_public do
    442
  end

  @doc false
  def private do
    41
  end
end
