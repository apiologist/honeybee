defmodule Benchee.Plug do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get("/1/:benchmark", do: Benchee.Handler.bench(conn, benchmark))
  get("/2/:benchmark", do: Benchee.Handler.bench(conn, benchmark))
  get("/3/:benchmark", do: Benchee.Handler.bench(conn, benchmark))
  get("/4/:benchmark", do: Benchee.Handler.bench(conn, benchmark))
  get("/5/:benchmark", do: Benchee.Handler.bench(conn, benchmark))
  get("/6/:benchmark", do: Benchee.Handler.bench(conn, benchmark))
  get("/7/:benchmark", do: Benchee.Handler.bench(conn, benchmark))
  get("/8/:benchmark", do: Benchee.Handler.bench(conn, benchmark))
  get("/9/:benchmark", do: Benchee.Handler.bench(conn, benchmark))
  get("/10/:benchmark", do: Benchee.Handler.bench(conn, benchmark))
end
