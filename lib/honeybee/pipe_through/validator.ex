defmodule Honeybee.PipeThrough.Validator do
  @moduledoc false
  use Honeybee.Utils.Types

  defmodule TypeError do
    use Honeybee.Utils.Error
  end

  @spec validate_types!(Macro.Env.t(), [atom()]) :: :ok
  def validate_types!(env, pipelines) do
    cond do
      !is_list(pipelines) ->
        raise TypeError,
          env: env,
          message:
            "Honeybee.pipe_through: expected pipelines to be a list, got: #{
              Macro.to_string(pipelines)
            }"

      true ->
        :ok
    end
  end
end
