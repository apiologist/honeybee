defmodule Honeybee.Test.Pipe do
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
      def bad_pipe(_conn), do: 1
    end

    pipe :test,     do: plug Middlewares, apply: :test
    pipe :nop,      do: plug Middlewares, apply: :nop
    pipe :raise,    do: plug Middlewares, apply: :test_raise
    pipe :bad_pipe, do: plug Middlewares, apply: :bad_pipe

    using :test
    get "/", do: plug Routes, :ok

    using :nop
    get "/test", do: plug Routes, :ok

    scope do
      using :raise
      get "/test/raise", do: plug Routes, :ok
    end

    scope do
      using :bad_pipe
      get "/test/bad_pipe", do: plug Routes, :ok
    end
  end

  describe "Runs pipes on routes" do
    test "Sets conn private on the returned conn" do
      conn =
        Plug.Test.conn("GET", "/")
        |> Router.call([])

      assert conn.private.test == "test"
      assert conn.status == 200
      assert conn.resp_body == "OK"
    end

    test "Using new pipes accumulates on the old pipes" do
      conn =
        Plug.Test.conn("GET", "/test")
        |> Router.call([])

      assert conn.private.test == "test"
      assert conn.status == 200
      assert conn.resp_body == "OK"
    end

    test "If a pipe raises the error propogates out of the router" do
      assert_raise RuntimeError, "Failure within test", fn ->
        Plug.Test.conn("GET", "/test/raise")
        |> Router.call([])
      end
    end

    test "If a pipe returns something which isn't a conn an error is raised" do
      assert_raise RuntimeError,
        "expected Honeybee.Test.Pipe.Router.Middlewares.call/2 " <>
        "to return a Plug.Conn, all plugs must receive a connection " <>
        "(conn) and return a connection, got: 1", fn ->
        Plug.Test.conn("GET", "/test/bad_pipe")
        |> Router.call([])
      end
    end
  end

  describe "Type Validations" do
    test "Pipe name must be an atom" do
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

          pipe "not a valid pipe name", do: plug Middleware, apply: :test
        end
      end
    end
  end
end
