defmodule Honeybee.Test.Methods do
  use ExUnit.Case, async: true

  defmodule Router do
    use Honeybee

    defmodule Routes do
      import Plug.Conn
      def head(conn, _opts), do: resp(conn, 200, "head")      
      def get(conn, _opts), do: resp(conn, 200, "get")
      def put(conn, _opts), do: resp(conn, 200, "put")
      def post(conn, _opts), do: resp(conn, 200, "post")
      def patch(conn, _opts), do: resp(conn, 200, "patch")
      def connect(conn, _opts), do: resp(conn, 200, "connect")
      def options(conn, _opts), do: resp(conn, 200, "options")
      def delete(conn, _opts), do: resp(conn, 200, "delete")
      def match(conn, _opts), do: resp(conn, 200, "match")
    end

    head "/test", Routes, :head
    get "/test", Routes, :get
    put "/test", Routes, :put
    post "/test", Routes, :post
    patch "/test", Routes, :patch
    connect "/test", Routes, :connect
    options "/test", Routes, :options
    delete "/test", Routes, :delete
    match _, "/test/match", Routes, :match
  end

  test "head" do
    conn =
      Plug.Test.conn("HEAD", "/test")
      |> Router.call([])

    assert conn.state == :set
    assert conn.resp_body == "head"
    assert conn.status == 200
  end

  test "get" do
    conn =
      Plug.Test.conn("GET", "/test")
      |> Router.call([])

    assert conn.state == :set
    assert conn.resp_body == "get"
    assert conn.status == 200
  end

  test "put" do
    conn =
      Plug.Test.conn("PUT", "/test")
      |> Router.call([])

    assert conn.state == :set
    assert conn.resp_body == "put"
    assert conn.status == 200
  end

  test "post" do
    conn =
      Plug.Test.conn("POST", "/test")
      |> Router.call([])

    assert conn.state == :set
    assert conn.resp_body == "post"
    assert conn.status == 200
  end

  test "patch" do
    conn =
      Plug.Test.conn("PATCH", "/test")
      |> Router.call([])

    assert conn.state == :set
    assert conn.resp_body == "patch"
    assert conn.status == 200
  end

  test "connect" do
    conn =
      Plug.Test.conn("CONNECT", "/test")
      |> Router.call([])

    assert conn.state == :set
    assert conn.resp_body == "connect"
    assert conn.status == 200
  end

  test "options" do
    conn =
      Plug.Test.conn("OPTIONS", "/test")
      |> Router.call([])

    assert conn.state == :set
    assert conn.resp_body == "options"
    assert conn.status == 200
  end

  test "delete" do
    conn =
      Plug.Test.conn("DELETE", "/test")
      |> Router.call([])

    assert conn.state == :set
    assert conn.resp_body == "delete"
    assert conn.status == 200
  end

  test "match" do
    conn =
      Plug.Test.conn("RANDOM", "/test/match")
      |> Router.call([])

    assert conn.state == :set
    assert conn.resp_body == "match"
    assert conn.status == 200
  end

  describe "Invalid input will cause TypeErrors during compilation" do
    test "path must be string" do
      assert_raise Honeybee.Route.Validator.TypeError, fn ->
        defmodule PathErrorRouter do
          use Honeybee
          defmodule Routes do
            def ok(conn, _opts), do: Plug.Conn.resp(conn, 200, "OK")
          end

          get :im_not_a_string, Routes, :ok
        end
      end
    end

    test "Target module must be a module" do
      assert_raise Honeybee.Route.Validator.TypeError, fn ->
        defmodule ModuleErrorRouter do
          use Honeybee
          defmodule Routes do
            def ok(conn, _opts), do: Plug.Conn.resp(conn, 200, "OK")
          end

          get "/test", :test, :ok
        end
      end
    end

    test "Target function must be an atom" do
      assert_raise Honeybee.Route.Validator.TypeError, fn ->
        defmodule FunctionErrorRouter do
          use Honeybee
          defmodule Routes do
            def ok(conn, _opts), do: Plug.Conn.resp(conn, 200, "OK")
          end

          get "/test", Routes, "im not an atom"
        end
      end
    end

    test "Options must be a list" do
      assert_raise Honeybee.Route.Validator.TypeError, fn ->
        defmodule OptionsErrorRouter do
          use Honeybee
          defmodule Routes do
            def ok(conn, _opts), do: Plug.Conn.resp(conn, 200, "OK")
          end

          get "/test", Routes, :ok, "Definitely not a list"
        end
      end
    end
  end
end