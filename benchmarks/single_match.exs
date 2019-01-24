"benchmarks/lib/single_route/*.ex"
|> Path.wildcard()
|> Enum.each(&Code.eval_file/1)

plug = %Plug.Conn{path_info: ["benchmark"]}

plug_opts = Benchee.Plug.init([])
plug_router = fn -> Benchee.Plug.call(plug, plug_opts) end
phoenix_opts = Benchee.Phoenix.init([])
phoenix_router = fn -> Benchee.Phoenix.call(plug, plug_opts) end
honeybee_opts = Benchee.Honeybee.init([])
honeybee_router = fn -> Benchee.Honeybee.call(plug, plug_opts) end

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
    html: [file: "benchmarks/results/single_match/results.html", auto_open: false]
  ],
  warmup: 5,
  time: 15
)
