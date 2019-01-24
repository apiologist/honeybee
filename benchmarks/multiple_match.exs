"benchmarks/lib/multiple_match/*.ex"
|> Path.wildcard()
|> Enum.each(&Code.eval_file/1)

routes = Enum.map(1..10, fn id -> %Plug.Conn{path_info: ["#{id}", "benchmark"]} end)

plug_opts = Benchee.Plug.init([])
plug_router = fn -> Enum.each(routes, &Benchee.Plug.call(&1, plug_opts)) end
phoenix_opts = Benchee.Phoenix.init([])
phoenix_router = fn -> Enum.each(routes, &Benchee.Phoenix.call(&1, plug_opts)) end
honeybee_opts = Benchee.Honeybee.init([])
honeybee_router = fn -> Enum.each(routes, &Benchee.Honeybee.call(&1, plug_opts)) end

Benchee.run(
  %{
    "Plug.Router" => plug_router,
    "Phoenix.Router" => phoenix_router,
    "Honeybee" => honeybee_router
  },
  formatters: [
    Benchee.Formatters.HTML,
    Benchee.Formatters.Console
  ],
  formatter_options: [
    html: [file: "benchmarks/results/multiple_match/results.html", auto_open: false]
  ],
  warmup: 5,
  time: 15
)
