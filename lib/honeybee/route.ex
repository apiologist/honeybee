defmodule Honeybee.Route do
  @moduledoc false
  use Honeybee.Utils.Types
  @attr_route :__honeybee_routes__
  defstruct [:line, :type, :scope, :verb, :path, :module, :method, :opts]

  @type t :: %Honeybee.Route{
          line: integer,
          type: :match | :forward,
          scope: [Honeybee.Scope.t()],
          verb: String.t() | Var.t() | nil,
          path: String.t(),
          module: Alias.t() | atom,
          method: atom,
          opts: keyword
        }

  @spec init(Macro.Env.t()) :: :ok
  def init(%Macro.Env{} = env) do
    Module.register_attribute(env.module, @attr_route, accumulate: true)
  end

  @spec create(
          Macro.Env.t(),
          :match | :forward,
          [Honeybee.Scope.t()],
          String.t() | Var.t() | nil,
          String.t(),
          Alias.t() | atom,
          atom | nil,
          keyword
        ) :: :ok
  def create(%Macro.Env{} = env, type, scope, verb, path, module, method, opts) do
    Honeybee.Route.Validator.validate_types!(env, type, verb, path, module, method, opts)

    route = %Honeybee.Route{
      line: env.line,
      type: type,
      scope: scope,
      verb: verb,
      path: path,
      module: module,
      method: method,
      opts: opts
    }

    Module.put_attribute(env.module, @attr_route, route)
  end

  @spec get(Macro.Env.t()) :: [Honeybee.Route.t()]
  def get(%Macro.Env{} = env) do
    Module.get_attribute(env.module, @attr_route)
  end
end
