defmodule Honeybee.Test do
  use ExUnit.Case, async: true

  defmodule Router do
    use Honeybee
  end

  test "Is pluggable" do
    assert function_exported?(Router, :call, 2)
    assert function_exported?(Router, :init, 1)
  end

  test "Raises requests" do
    assert_raise RuntimeError, "No matching route for request: GET /test",
      fn ->
        Router.call(Plug.Test.conn("GET", "/test"), [])
      end
  end
end
