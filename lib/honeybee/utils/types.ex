defmodule Honeybee.Utils.Types.Alias do
  @moduledoc false
  @type t :: {:__aliases__, keyword(), [atom]}
end

defmodule Honeybee.Utils.Types.Var do
  @moduledoc false
  @type t :: {atom, keyword(), atom}
end

defmodule Honeybee.Utils.Types do
  @moduledoc false
  @spec alias?(term) :: boolean
  def alias?({:__aliases__, meta, atoms}) when is_list(atoms) and is_list(meta) do
    true
  end

  def alias?(_) do
    false
  end

  @spec var?(term) :: boolean
  def var?({var, meta, context})
      when is_atom(var) and is_list(meta) and is_atom(context) do
    true
  end

  def var?(_) do
    false
  end

  defmacro __using__(_opts \\ []) do
    quote do
      import Honeybee.Utils.Types
      alias Honeybee.Utils.Types.Alias
      alias Honeybee.Utils.Types.Var
    end
  end
end
