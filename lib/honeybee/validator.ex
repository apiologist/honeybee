defmodule Honeybee.Validator do
  @moduledoc false
  alias Honeybee.Plug
  alias Honeybee.Pipeline
  alias Honeybee.PipeThrough
  alias Honeybee.Scope
  alias Honeybee.Route

  def validate_pipeline(env, %Pipeline{line: line, name: name, plugs: plugs}) do
  end

  def validate_plug do
  end

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

  # @spec validate_pipeline!(Macro.Env.t(), Honeybee.Pipeline.t()) :: any
  # def validate_pipeline!(env, %Honeybee.Pipeline{plugs: plugs, name: name, line: line}) do
  #   cond do
  #     !is_atom(name) -> raise "LOL"
  #   end

  #   Enum.each(plugs, &validate_plug!(env, &1))
  #   :ok
  # end

  # def validate_plug!(env, %Honeybee.Plug{plug: plug, line: line, opts: opts}) do
  #   plug = Macro.expand(plug, env)

  #   cond do
  #     !is_atom(plug) -> raise "LOL"
  #   end

  #   :ok
  # end

  # def is_valid_plug?(plug) do
  #   case Atom.to_string(plug) do
  #     ":Elixir." <> _ -> is_valid_module_plug?(plug)
  #   end
  # end
end
