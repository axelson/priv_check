defmodule ExampleDep.PubMacros do
  defmacro expand_priv do
    priv_function()

    quote do
      ExampleDep.PubMacros.hidden_func()
    end
  end

  defmacro expand_funcs do
    quote location: :keep, unquote: false do
      def good_func do
        ExampleDep.Private.add(1, 2)
      end
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
