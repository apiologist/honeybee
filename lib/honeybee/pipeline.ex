defmodule Honeybee.Pipeline do
  @moduledoc false
  @attr_pipelines :__honeybee_pipelines__
  defstruct [:line, :name, :plugs]

  @type t :: %Honeybee.Pipeline{
          line: integer(),
          name: atom(),
          plugs: [Honeybee.Plug.t()]
        }

  @spec init(Macro.Env.t()) :: :ok
  def init(%Macro.Env{} = env) do
    Module.register_attribute(env.module, @attr_pipelines, accumulate: true)
  end

  @spec create(Macro.Env.t(), atom(), Macro.t()) :: :ok
  def create(%Macro.Env{} = env, name, block) do
    Honeybee.Pipeline.Validator.validate_types!(env, name, block)
    plugs = Honeybee.Utils.Resolver.resolve(env, block)

    Module.put_attribute(env.module, @attr_pipelines, %Honeybee.Pipeline{
      line: env.line,
      name: name,
      plugs: plugs
    })
  end

  @spec get(Macro.Env.t()) :: [Honeybee.Pipeline.t()]
  def get(%Macro.Env{} = env) do
    Module.get_attribute(env.module, @attr_pipelines)
  end
end
