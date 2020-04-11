# Implementation from Credo https://github.com/rrrene/credo/ which is also where
# this license is from
#
# Copyright (c) 2015-2020 René Föhring
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
defmodule PrivCheck.ExsLoader do
  @moduledoc false

  def parse(exs_string, safe \\ false)

  def parse(exs_string, true) do
    case Code.string_to_quoted(exs_string) do
      {:ok, ast} ->
        {:ok, process_exs(ast)}

      {:error, value} ->
        {:error, value}
    end
  end

  def parse(exs_string, false) do
    {result, _binding} = Code.eval_string(exs_string)

    {:ok, result}
  rescue
    error ->
      case error do
        %SyntaxError{description: "syntax error before: " <> trigger, line: line_no} ->
          {:error, {line_no, "syntax error before: ", trigger}}

        error ->
          {:error, error}
      end
  end

  @doc false
  def parse_safe(exs_string) do
    case Code.string_to_quoted(exs_string) do
      {:ok, ast} ->
        process_exs(ast)

      _ ->
        %{}
    end
  end

  defp process_exs(v)
       when is_atom(v) or is_binary(v) or is_float(v) or is_integer(v),
       do: v

  defp process_exs(list) when is_list(list) do
    Enum.map(list, &process_exs/1)
  end

  defp process_exs({:sigil_w, _, [{:<<>>, _, [list_as_string]}, []]}) do
    String.split(list_as_string, ~r/\s+/)
  end

  # TODO: support regex modifiers
  defp process_exs({:sigil_r, _, [{:<<>>, _, [regex_as_string]}, []]}) do
    Regex.compile!(regex_as_string)
  end

  defp process_exs({:%{}, _meta, body}) do
    process_map(body, %{})
  end

  defp process_exs({:{}, _meta, body}) do
    process_tuple(body, {})
  end

  defp process_exs({:__aliases__, _meta, name_list}) do
    Module.safe_concat(name_list)
  end

  defp process_exs({{:__aliases__, _meta, name_list}, options}) do
    {Module.safe_concat(name_list), process_exs(options)}
  end

  defp process_exs({key, value}) when is_atom(key) or is_binary(key) do
    {process_exs(key), process_exs(value)}
  end

  defp process_tuple([], acc), do: acc

  defp process_tuple([head | tail], acc) do
    acc = process_tuple_item(head, acc)
    process_tuple(tail, acc)
  end

  defp process_tuple_item(value, acc) do
    Tuple.append(acc, process_exs(value))
  end

  defp process_map([], acc), do: acc

  defp process_map([head | tail], acc) do
    acc = process_map_item(head, acc)
    process_map(tail, acc)
  end

  defp process_map_item({key, value}, acc)
       when is_atom(key) or is_binary(key) do
    Map.put(acc, key, process_exs(value))
  end
end
