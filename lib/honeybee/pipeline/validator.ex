defmodule Honeybee.Pipeline.Validator do
  @moduledoc false
  use Honeybee.Utils.Types

  defmodule TypeError do
    use Honeybee.Utils.Error
  end

  @spec validate_types!(Macro.Env.t(), atom, term()) :: :ok
  def validate_types!(env, name, _block) do
    cond do
      !is_atom(name) ->
        raise TypeError,
          env: env,
          message: "Honeybee.pipeline: expected name to be atom, got: #{Macro.to_string(name)}"

      true ->
        :ok
    end
  end
end
