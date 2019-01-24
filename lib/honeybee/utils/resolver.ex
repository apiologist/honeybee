defmodule Honeybee.Utils.Resolver do
  @moduledoc false
  def resolve(env, {:__block__, _, statements}), do: __resolve__(env, statements)

  def resolve(env, statement), do: __resolve__(env, [statement])

  defp __resolve__(env, statements) do
    statements
    |> Macro.prewalk(&Macro.expand(&1, env))
  end
end
