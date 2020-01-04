defmodule Honeybee.Test.Scope do
  use ExUnit.Case, async: true

  defmodule Router do
    use Honeybee

    defmodule Routes do
      use Honeybee.Handler
      import Plug.Conn

      def ok(conn, _opts), do: resp(conn, 200, "OK")
      def test3(conn, _opts), do: resp(conn, 200, "TEST3")
    end

    def test_global(conn, _opts), do: Plug.Conn.put_private(conn, :test_global, :test_global)
    def test1(conn, _opts), do: Plug.Conn.put_private(conn, :test1, :test1)
    def test2(conn, _opts), do: Plug.Conn.put_private(conn, :test2, :test2)

    plug :test_global
    scope do
      plug :test1
      get "/test1", do: plug Routes, action: :ok
    end

    scope "/test1" do
      plug :test2
      get "/test2", do: plug Routes, action: :ok

      scope "/test2" do
        get "/test3", do: plug Routes, action: :test3
      end
    end
  end

  describe "Scopes seperate pipe environments" do
    test "global plugs are always active" do
      conn =
        Plug.Test.conn("GET", "/test1")
        |> Router.call([])
      assert conn.private.test_global == :test_global

      conn =
        Plug.Test.conn("GET", "/test1/test2")
        |> Router.call([])
      assert conn.private.test_global == :test_global
    end

    test "plugs belong to the scope in which they are declared" do
      conn =
        Plug.Test.conn("GET", "/test1")
        |> Router.call([])
      assert conn.private.test_global == :test_global
      assert conn.private[:test1] == :test1
      refute conn.private[:test2] == :test2

      conn =
        Plug.Test.conn("GET", "/test1/test2")
        |> Router.call([])
      assert conn.private.test_global == :test_global
      refute conn.private[:test1] == :test1
      assert conn.private[:test2] == :test2
    end

    test "scopes inside scopes work properly" do
      conn =
        Plug.Test.conn("GET", "/test1/test2/test3")
        |> Router.call([])
      assert conn.private.test_global == :test_global
      refute conn.private[:test1] == :test1
      assert conn.private[:test2] == :test2
      assert conn.status == 200
      assert conn.resp_body == "TEST3"
    end
  end

  describe "TypeErrors" do
    test "Scopes must scope a string" do
      assert_raise FunctionClauseError, fn ->
        defmodule InvalidScopeStringRouter do
          use Honeybee

          defmodule Routes do
            def ok(conn, _opts), do: Plug.Conn.resp(conn, 200, "OK")
          end

          scope :invalid_scope do
            get "/test", Routes, :ok
          end
        end
      end
    end
  end
end
