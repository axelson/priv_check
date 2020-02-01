defmodule PrivCheck.DocChecker do
  @moduledoc """
  Find docs of module, caching results for performance

  Depends heavily on the documentation layout described and implemented in EEP 48:
  http://erlang.org/eeps/eep-0048.html
  """

  @type visibility :: :public | :private | :not_found

  @doc """
  Check if the given module is considered public
  """
  def public?(mod) when is_atom(mod) do
    case mod_visibility(mod) do
      :public -> true
      :private -> false
      :not_found -> false
    end
  end

  def public_fun?({mod, fun, arity} = mfa) do
    case mfa_visibility({mod, fun, arity}) |> IO.inspect(label: "mfa vis") do
      :public -> true
      :private -> false
      :not_found -> true
    end
    |> IO.inspect(label: "public_fun?(#{inspect(mfa)})")
  end

  @doc """
  Check the visiblity type of the given module
  """
  @spec mod_visibility(module()) :: visibility()
  def mod_visibility(mod) do
    case Code.fetch_docs(mod) do
      # No @moduledoc annotation
      {:docs_v1, _line, :elixir, _format, :none, _metadata, _docs} ->
        :public

      # @moduledoc false
      {:docs_v1, _line, :elixir, _format, :hidden, _metadata, _docs} ->
        :private

      {:docs_v1, _line, :elixir, _format, moduledocs, _metadata, _docs} when is_map(moduledocs) ->
        :public

      {:error, _} ->
        :not_found
    end
  end

  @spec mfa_visibility(mfa()) :: visibility()
  def mfa_visibility({mod, fun, arity}) do
    case Code.fetch_docs(mod) do
      # No @moduledoc annotation
      {:docs_v1, _line, :elixir, _format, :none, _metadata, docs} ->
        fun_visibility(fun, arity, docs)

      # @moduledoc false
      {:docs_v1, _line, :elixir, _format, :hidden, _metadata, _docs} ->
        :private

      {:docs_v1, _line, :elixir, _format, moduledocs, _metadata, docs} when is_map(moduledocs) ->
        fun_visibility(fun, arity, docs)

      {:error, _} ->
        :not_found
    end
  end

  @spec fun_visibility(atom(), non_neg_integer(), list()) :: visibility()
  defp fun_visibility(fun, arity, docs) do
    Enum.find_value(docs, :not_found, fn
      # No @doc annotation
      {{:function, ^fun, ^arity}, _line, _signature, :none, _metadata} ->
        :public

      # @doc false
      {{:function, ^fun, ^arity}, _line, _signature, :hidden, _metadata} ->
        :private

      # has @doc entry
      {{:function, ^fun, ^arity}, _line, _signature, func_docs, _metadata} when is_map(func_docs) ->
        :public

      # No @doc annotation
      {{:macro, ^fun, ^arity}, _line, _signature, :none, _metadata} ->
        :public

      # @doc false
      {{:macro, ^fun, ^arity}, _line, _signature, :hidden, _metadata} ->
        :private

      # has @doc entry
      {{:macro, ^fun, ^arity}, _line, _signature, func_docs, _metadata} when is_map(func_docs) ->
        :public

      _ ->
        false
    end)
  end
end
