defmodule Honeybee.Test do
  use ExUnit.Case, async: true

  defmodule Router do
    use Honeybee
  end

  test "Is pluggable" do
    assert function_exported?(Router, :call, 2)
    assert function_exported?(Router, :init, 1)
  end

  test "Returns unmodified conn when no match is found" do
    conn = Plug.Test.conn("GET", "/test")
    assert conn == Router.call(conn, [])
  end
end
