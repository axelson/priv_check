defmodule ExampleDep.PubMacros do
  defmacro expand_priv do
    priv_function()

    quote do
      ExampleDep.PubMacros.hidden_func()
    end
  end

  @doc false
  def hidden_func do
    11
  end

  defp priv_function do
    10
  end
end
