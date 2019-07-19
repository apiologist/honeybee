defmodule Honeybee.Scope do
  @moduledoc false
  @attr_scope :__honeybee_scope__

  defstruct [:line, :path, :using]

  @type t :: %Honeybee.Scope{
          line: integer(),
          path: String.t(),
          using: [Honeybee.Using.t()]
        }

  @spec init(Macro.Env.t()) :: :ok
  def init(%Macro.Env{} = env) do
    Module.put_attribute(env.module, @attr_scope, [
      %Honeybee.Scope{path: "/", using: [], line: env.line}
    ])
  end

  @spec create(Macro.Env.t(), String.t(), Macro.t()) :: :ok
  def create(%Macro.Env{} = env, path, block) do
    Honeybee.Scope.Validator.validate_types!(env, path, block)
    push(env, %Honeybee.Scope{line: env.line, path: path, using: []})
    Honeybee.Utils.Resolver.resolve(env, block)
    popn(env)
  end

  @spec using(Macro.Env.t(), Honeybee.Using.t()) :: :ok
  def using(%Macro.Env{} = env, using) do
    scope = pop(env)
    push(env, %Honeybee.Scope{scope | using: [using | scope.using]})
  end

  @spec in_scope?(Macro.Env.t()) :: true | false
  def in_scope?(env), do: length(get(env)) > 1

  @spec get(Macro.Env.t()) :: [Honeybee.Scope.t()]
  def get(%Macro.Env{} = env) do
    Module.get_attribute(env.module, @attr_scope)
  end

  @spec push(Macro.Env.t(), Honeybee.Scope.t()) :: :ok
  def push(%Macro.Env{} = env, scope) do
    Module.put_attribute(env.module, @attr_scope, [scope | get(env)])
  end

  @spec pop(Macro.Env.t()) :: Honeybee.Scope.t()
  def pop(%Macro.Env{} = env) do
    [top | scope] = get(env)
    Module.put_attribute(env.module, @attr_scope, scope)
    top
  end

  @spec popn(Macro.Env.t()) :: :ok
  def popn(%Macro.Env{} = env) do
    [_ | scope] = get(env)
    Module.put_attribute(env.module, @attr_scope, scope)
  end
end
