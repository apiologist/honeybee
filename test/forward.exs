defmodule Honeybee.Test.Forward do
  use ExUnit.Case, async: true

  defmodule Router do
    use Honeybee

    defmodule ForwardRouter do
      use Honeybee

      defmodule Routes do
        def ok(conn, _opts), do: Plug.Conn.resp(conn, 200, "ok")
      end

      get "/test", Routes, :ok
    end

    forward "/forward-test", ForwardRouter
  end

  test "Forwards requests to the forwarded router" do
    conn =
      Plug.Test.conn("GET", "/forward-test/test")
      |> Router.call([])

    assert conn.status == 200
    assert conn.resp_body == "ok"
  end
end