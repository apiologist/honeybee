defmodule Honeybee.Utils.Path do
  @moduledoc false
  defmodule InvalidPathError do
    use Honeybee.Utils.Error
  end

  def compile(path) do
    {compile_pattern(path), compile_params(path)}
  end

  def compile_pattern(path) do
    path
    |> String.split("/", trim: true)
    |> Enum.map(&String.split(&1, ~r/(?=[\:\*])/))
    |> Enum.reduce([], fn
      ["", "*" <> glob], acc ->
        acc ++ var(glob)

      [static, "*" <> glob], acc ->
        acc ++ [merge(static, var("_" <> glob))] ++ var(glob)

      ["", ":" <> dynamic], acc ->
        acc ++ [var(dynamic)]

      [static, ":" <> dynamic], acc ->
        acc ++ [merge(static, var(dynamic))]

      [static], acc ->
        acc ++ [static]
    end)
    |> Macro.escape(unquote: true)
  end

  def compile_params(path) do
    path
    |> String.split("/", trim: true)
    |> Enum.map(&String.split(&1, ~r/(?=[\:\*])/))
    |> Enum.reduce(%{}, fn
      ["", "*" <> glob], var_map ->
        Map.merge(var_map, %{glob => var(glob)})

      [_, "*" <> glob], var_map ->
        Map.merge(var_map, %{glob => [var("_" <> glob) | var(glob)]})

      [_, ":" <> dynamic], var_map ->
        Map.merge(var_map, %{dynamic => var(dynamic)})

      [_], var_map ->
        var_map
    end)
    |> Macro.escape(unquote: true)
  end

  defp var(str, context \\ __MODULE__) do
    {:unquote, [], [Macro.var(String.to_atom(str), context)]}
  end

  defp merge(static, dynamic) do
    {:unquote, [],
     [{:<>, [context: Elixir, import: Kernel], Macro.escape([static, dynamic], unquote: true)}]}
  end
end
