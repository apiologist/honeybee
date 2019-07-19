defmodule Honeybee.Validator do
  @moduledoc false

  def ensure_exports!(env, methods) do
    Enum.each(methods, fn {method, arity} ->
      cond do
        !function_exported?(env.module, method, arity) -> raise "nope"
        true -> :ok
      end
    end)
  end

  def ensure_defined!(env, methods) do
    Enum.each(methods, fn {method, arity} ->
      cond do
        !Module.defines?(env.module, {method, arity}) -> raise "nope"
        true -> :ok
      end
    end)
  end
end
