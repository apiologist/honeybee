defmodule Benchee.Plug do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get("/:benchmark", do: Benchee.Handler.bench(conn, []))
end
