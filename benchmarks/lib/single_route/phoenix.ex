defmodule Benchee.Phoenix do
  use Phoenix.Router

  get("/benchmark", Benchee.Handler, :bench)
end
