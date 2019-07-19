defmodule Honeybee.Using.Validator do
  @moduledoc false
  use Honeybee.Utils.Types

  defmodule TypeError do
    use Honeybee.Utils.Error
  end

  @spec validate_types!(Macro.Env.t(), [atom()]) :: :ok
  def validate_types!(env, pipes) do
    cond do
      !is_list(pipes) ->
        raise TypeError,
          env: env,
          message:
            "Honeybee.using: expected pipes to be a list, got: #{
              Macro.to_string(pipes)
            }"

      true ->
        :ok
    end
  end
end
