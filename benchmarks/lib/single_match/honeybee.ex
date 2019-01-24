defmodule Benchee.Honeybee do
  use Honeybee

  get("/:benchmark", Benchee.Handler, :bench)
end
