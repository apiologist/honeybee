defmodule RouteGenerator do
  defmodule Handler do
    use Phoenix.Controller

    def init(opts), do: opts
    def call(conn, _opts), do: benchmark(conn)

    def benchmark(conn), do: Plug.Conn.resp(conn, 200, "")
  end

  def gen_path_part(len) do
    :crypto.strong_rand_bytes(len) |> Base.url_encode64 |> binary_part(0, len)
  end

  def gen_path_param(len) do
    to_string Enum.take_random(?a..?z, len)
  end

  def path_param?(parts, path_param_parts) do
    :rand.uniform < (path_param_parts/parts)
  end

  def gen_path(path_parts, _ \\ 0, _ \\ false)
  def gen_path(0, _, true), do: "/*" <> gen_path_param(8)
  def gen_path(0, _, false), do: ""
  def gen_path(a, _, _) when a < 0, do: raise ArgumentError, "Cannot generate negative number of path parts"
  def gen_path(path_parts, param_parts, has_glob) do
    with using_path_param <- path_param?(path_parts, param_parts) do
      case using_path_param do
        true -> "/:" <> gen_path_param(8) <> gen_path(path_parts - 1, param_parts - 1, has_glob)
        false -> "/" <> gen_path_part(8) <> gen_path(path_parts - 1, param_parts, has_glob)
      end
    end
  end

  def gen_routes(num_routes, opts \\ []) do
    max_path_parts = Keyword.get(opts, :max_path_parts, 5)
    min_path_parts = Keyword.get(opts, :min_path_parts, 0)
    max_path_params = Keyword.get(opts, :max_path_params, 0)
    min_path_params = Keyword.get(opts, :min_path_params, 0)
    glob_likelyhood = Keyword.get(opts, :glob_likelyhood, 0)
    method_weights = Keyword.get(opts, :method_weights, [all: 1])
    
    method_list = for {method, weight} <- method_weights, _ <- 1..weight do
      method
    end


    for _ <- 1..num_routes do
      path_parts = Enum.random(min_path_parts..max_path_parts)
      path_params = Enum.random(min_path_params..max_path_params)
      has_glob = :rand.uniform() < glob_likelyhood

      method = Enum.random(method_list)
      handler = Handler

      path = gen_path(path_parts, path_params, has_glob)

      %{ path: path, method: method, handler: handler }
    end
  end

  def gen_plugs(routes, num_plugs) do
    plugs = Enum.map(1..num_plugs, fn _ -> Enum.random(routes) end)
    for %{method: method, path: path} <- plugs do
      String.split(path, "/")
      |> Enum.map(fn
        ":" <> _ -> "/" <> gen_path_part(16)
        "*" <> _ -> gen_path Enum.random(1..4)
        path_part -> "/" <> path_part
      end)
      |> Enum.join("")
      Plug.Test.conn(method, path)
    end
  end
end
