defmodule Honeybee.Test.Plug do
  use ExUnit.Case, async: true

  defmodule Router do
    use Honeybee

    defmodule MyOwn.JSON.Decoder do
      def decode!(_) do 1 end
    end

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
        id = Keyword.fetch!(opts, :id)
        private = conn.private
          |> Map.put_new(:test, [])
          |> Map.get_and_update(:test, &{&1, [id | &1]})
          |> elem(1)
        
        %Conn{conn | private: private}
      end
    end

    defp set_id(conn, opts) do
      Middlewares.call(conn, opts)
    end

    defp test_raise(_, _) do
      raise "im an error"
    end

    plug Plug.Parsers,
      parsers: [:urlencoded, :json],
      json_decoder: MyOwn.JSON.Decoder

    get "/", do: plug Routes, :ok
    
    plug :set_id, id: 1
    plug Middlewares, id: 2
    
    get "/test", do: plug Routes, :ok

    plug :test_raise
    get "/raise", do: plug Routes, :ok
  end

  describe "Runs plugs on routes" do
    test "Sets conn private on the returned conn" do
      conn =
        Plug.Test.conn("GET", "/")
        |> Router.call([])

      assert conn.status == 200
      assert conn.resp_body == "OK"
    end

    test "Using new plugs accumulates on the old pipes" do
      conn =
        Plug.Test.conn("GET", "/test")
        |> Router.call([])

      assert conn.private.test == [2, 1]
      assert conn.status == 200
      assert conn.resp_body == "OK"
    end

    test "If a plug raises the error propogates out of the router" do
      assert_raise RuntimeError, "im an error", fn ->
        Plug.Test.conn("GET", "/raise")
        |> Router.call([])
      end
    end
  end
end
