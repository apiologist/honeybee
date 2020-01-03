defmodule Honeybee.Test.Composition do
  use ExUnit.Case, async: true

  defmodule Router do
    use Honeybee

    defmodule Routes do
      use Honeybee.Handler
      import Plug.Conn

      def ok(conn, _opts), do: resp(conn, 200, "OK")
    end

    defmodule Middlewares do
      use Honeybee.Handler
      import Plug.Conn

      def nop(conn, _), do: conn
      def test(conn, _), do: put_private(conn, :test, "test")
      def test_raise(_conn, _), do: raise "Failure within test"
      def bad_plug(_conn, _), do: 1
    end

    composition :middlewares do
      plug Middlewares, action: opts
    end

    plug :middlewares, :test
    get "/", do: plug Routes, action: :ok

    plug :middlewares, :nop
    get "/test", do: plug Routes, action: :ok

    scope do
      plug :middlewares, :test_raise
      get "/test/raise", do: plug Routes, action: :ok
    end

    scope do
      plug :middlewares, :bad_plug
      get "/test/bad_plug", do: plug Routes, action: :ok
    end
  end

  describe "Runs plugs on routes" do
    test "Sets conn private on the returned conn" do
      conn =
        Plug.Test.conn("GET", "/")
        |> Router.call([])

      assert conn.private.test == "test"
      assert conn.status == 200
      assert conn.resp_body == "OK"
    end

    test "Using new plugs accumulates on the old plugs" do
      conn =
        Plug.Test.conn("GET", "/test")
        |> Router.call([])

      assert conn.private.test == "test"
      assert conn.status == 200
      assert conn.resp_body == "OK"
    end

    test "If a plug raises the error propogates out of the router" do
      assert_raise RuntimeError, "Failure within test", fn ->
        Plug.Test.conn("GET", "/test/raise")
        |> Router.call([])
      end
    end

    test "If a plug returns something which isn't a conn an error is raised" do
      assert_raise RuntimeError,
        "expected honeybee_action_call/2 " <>
        "to return a Plug.Conn, all plugs must receive a connection " <>
        "(conn) and return a connection, got: 1", fn ->
        Plug.Test.conn("GET", "/test/bad_plug")
        |> Router.call([])
      end
    end
  end

  describe "Type Validations" do
    test "Composition name must be an atom" do
      assert_raise FunctionClauseError, fn ->
        defmodule BadNameRouter do
          use Honeybee

          defmodule Routes do
            def ok(conn, _opts), do: Plug.Conn.resp(conn, 200, "OK")
          end

          defmodule Middleware do
            def init(opts), do: opts
            def call(conn, opts) do
              action = Keyword.fetch!(opts, :apply)
              apply(__MODULE__, action, [conn])
            end

            def test(conn), do: conn
          end

          composition "not a valid composition name", do: plug Middleware, apply: :test
        end
      end
    end
  end
end
