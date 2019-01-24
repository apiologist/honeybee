defmodule Honeybee.Plug do
  @moduledoc false
  use Honeybee.Utils.Types
  defstruct [:plug, :opts, :guards, :line]

  @type t :: %Honeybee.Plug{
          plug: Alias.t() | atom,
          opts: keyword,
          guards: term,
          line: integer
        }

  @spec create(Macro.Env.t(), Alias.t() | atom, keyword, term) :: Honeybee.Plug.t()
  def create(env, plug, opts, guards) do
    Honeybee.Plug.Validator.validate_types!(env, plug, opts)
    %Honeybee.Plug{line: env.line, plug: plug, opts: opts, guards: guards}
  end

  @spec as_plug(Honeybee.Plug.t()) :: {Alias.t() | atom, keyword, term}
  def as_plug(%Honeybee.Plug{plug: plug, opts: opts, guards: guards}) do
    {plug, opts, guards}
  end
end
