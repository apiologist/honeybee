defmodule Honeybee.Plug.Validator do
  @moduledoc false
  use Honeybee.Utils.Types

  defmodule TypeError do
    use Honeybee.Utils.Error
  end

  @spec validate_types!(Macro.Env.t(), Alias.t() | atom, keyword()) :: :ok
  def validate_types!(env, plug, opts) do
    cond do
      !is_atom(plug) && !alias?(plug) ->
        raise TypeError,
          env: env,
          message:
            "Honeybee.plug: expected plug to be atom or module, got: #{Macro.to_string(plug)}"

      !Keyword.keyword?(opts) ->
        raise TypeError,
          env: env,
          message: "Honeybee.plug: expected opts to be keyword, got: #{Macro.to_string(opts)}"

      true ->
        :ok
    end
  end
end
