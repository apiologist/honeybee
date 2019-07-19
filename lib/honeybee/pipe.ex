defmodule Honeybee.Pipe do
  @moduledoc false
  @attr_pipes :__honeybee_pipes__
  defstruct [:line, :name, :plugs]

  @type t :: %Honeybee.Pipe{
          line: integer(),
          name: atom(),
          plugs: [Honeybee.Plug.t()]
        }

  @spec init(Macro.Env.t()) :: :ok
  def init(%Macro.Env{} = env) do
    Module.register_attribute(env.module, @attr_pipes, accumulate: true)
  end

  @spec create(Macro.Env.t(), atom(), Macro.t()) :: :ok
  def create(%Macro.Env{} = env, name, block) do
    Honeybee.Pipe.Validator.validate_types!(env, name, block)
    plugs = Honeybee.Utils.Resolver.resolve(env, block)

    Module.put_attribute(env.module, @attr_pipes, %Honeybee.Pipe{
      line: env.line,
      name: name,
      plugs: plugs
    })
  end

  @spec get(Macro.Env.t()) :: [Honeybee.Pipe.t()]
  def get(%Macro.Env{} = env) do
    Module.get_attribute(env.module, @attr_pipes)
  end
end
