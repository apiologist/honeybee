defmodule Honeybee.Scope.Validator do
  @moduledoc false
  defmodule TypeError do
    use Honeybee.Utils.Error
  end

  @spec validate_types!(Macro.Env.t(), String.t(), term()) :: :ok
  def validate_types!(env, path, _block) do
    cond do
      !String.valid?(path) ->
        raise TypeError,
          env: env,
          message: "Honeybee.scope: expected path to be string, got: #{Macro.to_string(path)}"

      true ->
        :ok
    end
  end
end
