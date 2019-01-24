defmodule Benchee.Honeybee do
  use Honeybee

  pipeline :test do
    plug(:test)
  end

  def test(conn, _) do
    %{conn | method: "POST"}
  end

  pipe_through(:test)

  get("/1/:benchmark", Benchee.Handler, :bench)
  get("/2/:benchmark", Benchee.Handler, :bench)
  get("/3/:benchmark", Benchee.Handler, :bench)
  get("/4/:benchmark", Benchee.Handler, :bench)
  get("/5/:benchmark", Benchee.Handler, :bench)
  get("/6/:benchmark", Benchee.Handler, :bench)
  get("/7/:benchmark", Benchee.Handler, :bench)
  get("/8/:benchmark", Benchee.Handler, :bench)
  get("/9/:benchmark", Benchee.Handler, :bench)
  get("/10/:benchmark", Benchee.Handler, :bench)
end
