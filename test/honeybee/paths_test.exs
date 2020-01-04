defmodule Honeybee.Test.Paths do
  use ExUnit.Case, async: true

  defmodule Router do
    use Honeybee

    defmodule Routes do
      use Honeybee.Handler
      import Plug.Conn

      def test_dynamic(%Plug.Conn{path_params: %{"id" => id}} = conn, _opts) do
        put_private(conn, :id, id)
      end
      def test_partial_dynamic(%Plug.Conn{path_params: %{"id" => id}} = conn, _opts) do
        put_private(conn, :id, id)
      end
      def test_glob(%Plug.Conn{path_params: %{"glob" => glob}} = conn, _opts) do
        put_private(conn, :glob, glob)
      end
      def test_partial_glob(%Plug.Conn{path_params: %{"glob" => glob}} = conn, _opts) do
        put_private(conn, :glob, glob)
      end
    end

    get "/test/partial-:id", do: plug Routes, action: :test_partial_dynamic
    get "/test/:id", do: plug Routes, action: :test_dynamic
    get "/test/partial-*glob", do: plug Routes, action: :test_partial_glob
    get "/test/*glob", do: plug Routes, action: :test_glob
  end

  test "dynamic route" do
    conn =
      Plug.Test.conn("GET", "/test/1")
      |> Router.call([])

    assert conn.private.id == "1"
  end

  test "dynamic partial route" do
    conn =
      Plug.Test.conn("GET", "/test/partial-1")
      |> Router.call([])

    assert conn.private.id == "1"
  end

  test "globbing route" do
    conn =
      Plug.Test.conn("GET", "/test/glob/route")
      |> Router.call([])

    assert conn.private.glob == ["glob", "route"]
  end

  test "globbing partial route" do
    conn =
      Plug.Test.conn("GET", "/test/partial-glob/route")
      |> Router.call([])

    assert conn.private.glob == ["glob", "route"]
  end
end
