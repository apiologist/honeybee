defmodule Benchee.Plug do
  use Plug.Router

  plug(:match)
  plug(:test)
  plug(:dispatch)

  def test(conn, _) do
    %{conn | method: "POST"}
  end

  get("/1/:benchmark", do: Benchee.Handler.bench(conn, []))
  get("/2/:benchmark", do: Benchee.Handler.bench(conn, []))
  get("/3/:benchmark", do: Benchee.Handler.bench(conn, []))
  get("/4/:benchmark", do: Benchee.Handler.bench(conn, []))
  get("/5/:benchmark", do: Benchee.Handler.bench(conn, []))
  get("/6/:benchmark", do: Benchee.Handler.bench(conn, []))
  get("/7/:benchmark", do: Benchee.Handler.bench(conn, []))
  get("/8/:benchmark", do: Benchee.Handler.bench(conn, []))
  get("/9/:benchmark", do: Benchee.Handler.bench(conn, []))
  get("/10/:benchmark", do: Benchee.Handler.bench(conn, []))
end
