defmodule Honeybee.Handler.Test do
  use ExUnit.Case, async: true
  defmodule Handler do
    use Honeybee.Handler
    import Plug.Conn

    plug :action_test_plug when action in [:create]
    plug :method_test_plug when method in ["GET"]

    def action_test_plug(conn, _opts), do: put_private(conn, :action, "action")
    def method_test_plug(conn, _opts), do: put_private(conn, :method, "method")

    def create(conn, _opts), do: resp(conn, 200, "create")
    def ok(conn, _opts), do: resp(conn, 200, "")
  end

  test "No plugs activated when method is POST and action is :ok" do
    result = Handler.call(Plug.Test.conn("POST", "/"), Handler.init([action: :ok]))

    assert result.status == 200
    assert result.resp_body == ""
    assert result.private == %{}
  end

  test "method_test_plug called when method is GET and action is :ok" do
    result = Handler.call(Plug.Test.conn("GET", "/"), Handler.init([action: :ok]))

    assert result.status == 200
    assert result.resp_body == ""
    assert result.private == %{method: "method"}
  end

  test "action_test_plug activated when method is POST action is create" do
    result = Handler.call(Plug.Test.conn("POST", "/"), Handler.init([action: :create]))

    assert result.status == 200
    assert result.resp_body == "create"
    assert result.private == %{action: "action"}
  end

  test "Both action_test_plug and method_test_plug called when method is GET and action is :create" do
    result = Handler.call(Plug.Test.conn("GET", "/"), Handler.init([action: :create]))

    assert result.status == 200
    assert result.resp_body == "create"
    assert result.private == %{action: "action", method: "method"}
  end

  test "If action isn't defined, raises an error saying that the requested action does not exist" do
    assert_raise UndefinedFunctionError, "function Honeybee.Handler.Test.Handler.not_defined/2 is undefined or private", fn ->
      Handler.call(Plug.Test.conn("GET", "/"), Handler.init([action: :not_defined]))
    end
  end

  test "If called without an action, raises" do
    assert_raise FunctionClauseError, fn ->
      Handler.call(Plug.Test.conn("GET", "/"), [action: :not_defined])
    end
  end
end
