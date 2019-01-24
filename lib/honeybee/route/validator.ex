defmodule Honeybee.Route.Validator do
  @moduledoc false
  use Honeybee.Utils.Types

  defmodule TypeError do
    use Honeybee.Utils.Error
  end

  @spec validate_types!(
          Macro.Env.t(),
          :match | :forward,
          String.t() | Var.t() | nil,
          String.t(),
          Alias.t(),
          atom | nil,
          keyword
        ) :: :ok
  def validate_types!(env, :match, verb, path, module, method, opts) do
    cond do
      !String.valid?(verb) && !var?(verb) ->
        raise(TypeError,
          env: env,
          message:
            "Honeybee.match: expected method to be a string or '_', got: #{Macro.to_string(verb)}"
        )

      !String.valid?(path) ->
        raise(TypeError,
          env: env,
          message: "Honeybee.match: expected path to be a string, got: #{Macro.to_string(path)}"
        )

      !alias?(module) ->
        raise(TypeError,
          env: env,
          message:
            "Honeybee.match: expected module to be a module, got: #{Macro.to_string(module)}"
        )

      !is_atom(method) ->
        raise(TypeError,
          env: env,
          message:
            "Honeybee.match: expected function to be an atom, got: #{Macro.to_string(method)}"
        )

      !Keyword.keyword?(opts) ->
        raise(TypeError,
          env: env,
          message: "Honeybee.match: expected opts to be keyword, got:  #{Macro.to_string(opts)}"
        )

      true ->
        :ok
    end
  end

  def validate_types!(env, :forward, nil, path, module, nil, opts) do
    cond do
      !String.valid?(path) ->
        raise(TypeError,
          env: env,
          message: "Honeybee.forward: expected paths to be string, got: #{Macro.to_string(path)}"
        )

      !alias?(module) ->
        raise(TypeError,
          env: env,
          message:
            "Honeybee.forward: expected modules to be modules, got: #{Macro.to_string(module)}"
        )

      !Keyword.keyword?(opts) ->
        raise(TypeError,
          env: env,
          message: "Honeybee.forward: expected opts to be keyword, got:  #{Macro.to_string(opts)}"
        )

      true ->
        :ok
    end
  end
end
