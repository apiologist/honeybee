defmodule Honeybee.Test.Guards do
  use ExUnit.Case, async: true

  defmodule Router do
    use Honeybee

    defmodule Routes do
      use Honeybee.Handler
      import Plug.Conn

      def put_priv(conn, opts), do: put_private(conn, :priv, opts)
      def halt(conn, _), do: halt(conn)
      def resp(conn, _), do: resp(conn, 200, "")
    end

    match _, "" do
      plug Routes, action: :put_priv, opts: :a
      plug Routes, [action: :halt] when method in ["GET"]
      plug Routes, action: :resp
    end
  end

  test "halts connection on get" do
    conn =
      Plug.Test.conn("GET", "/")
      |> Router.call([])

    assert conn.halted == true
  end

  test "does not halt connection on post" do
    conn =
      Plug.Test.conn("POST", "/")
      |> Router.call([])

    assert conn.halted == false
  end
end
