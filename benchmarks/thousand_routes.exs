"benchmarks/lib/thousand_routes/*.ex"
|> Path.wildcard()
|> Enum.each(fn file ->
  IO.inspect("Compiling '#{file}'...'")
  time_start = Time.utc_now()
  Code.eval_file(file)
  time_end = Time.utc_now()
  IO.inspect("Compiled #{file} in #{Time.diff(time_end, time_start, :millisecond)}")
end)

routes =
  Enum.map(0..999, fn id ->
    %Plug.Conn{path_info: [String.pad_leading("#{id}", 3, "0"), "benchmark"]}
  end)

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
    html: [file: "benchmarks/results/thousand_routes/results.html", auto_open: false]
  ],
  warmup: 5,
  time: 15
)
