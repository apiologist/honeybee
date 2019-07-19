defmodule Honeybee.Using do
  @moduledoc false
  defstruct [:line, :pipes]

  @type t :: %Honeybee.Using{
          line: integer(),
          pipes: [atom()]
        }

  @spec create(Macro.Env.t(), [atom()]) :: Honeybee.Using.t()
  def create(env, pipes) do
    Honeybee.Using.Validator.validate_types!(env, pipes)
    %Honeybee.Using{line: env.line, pipes: pipes}
  end
end
