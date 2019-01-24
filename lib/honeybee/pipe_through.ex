defmodule Honeybee.PipeThrough do
  @moduledoc false
  defstruct [:line, :pipelines]

  @type t :: %Honeybee.PipeThrough{
          line: integer(),
          pipelines: [atom()]
        }

  @spec create(Macro.Env.t(), [atom()]) :: Honeybee.PipeThrough.t()
  def create(env, pipelines) do
    Honeybee.PipeThrough.Validator.validate_types!(env, pipelines)
    %Honeybee.PipeThrough{line: env.line, pipelines: pipelines}
  end
end
