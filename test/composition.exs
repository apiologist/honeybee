defmodule Honeybee.Test.Composition do
  use ExUnit.Case, async: true

  defmodule Router do
    use Honeybee

    defmodule Routes do
      import Plug.Conn

      def init(opts), do: opts
      def call(conn, opts), do: apply(__MODULE__, opts, [conn, opts])

      def ok(conn, _opts), do: resp(conn, 200, "OK")
    end

    defmodule Middlewares do
      alias Plug.Conn

      def init(opts), do: opts

      def call(conn, opts) do
        action = Keyword.fetch!(opts, :apply)
        apply(Middlewares, action, [conn])
      end

      def nop(conn), do: conn
      def test(conn), do: Conn.put_private(conn, :test, "test")
      def test_raise(_conn), do: raise "Failure within test"
      def bad_plug(_conn), do: 1
    end

    composition :tests, do: plug Middlewares, apply: opts

    plug :tests, :test
    get "/", do: plug Routes, :ok

    plug :tests, :nop
    get "/test", do: plug Routes, :ok

    scope do
      plug :tests, :test_raise
      get "/test/raise", do: plug Routes, :ok
    end

    scope do
      plug :tests, :bad_plug
      get "/test/bad_plug", do: plug Routes, :ok
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
        "expected Honeybee.Test.Composition.Router.Middlewares.call/2 " <>
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
