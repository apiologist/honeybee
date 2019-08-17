defmodule Mix.Tasks.Benchmark do
  use Mix.Task

  @shortdoc "Runs honeybee benchmarks."
  def run(_) do
    Application.ensure_all_started(:plug)
    Application.ensure_all_started(:phoenix)
    Application.ensure_all_started(:honeybee)

    benchmark_config = Application.get_all_env(:benchmark)

    {
      [
        {:calls_per_cycle, num_plugs},
        {:routes, num_routes}
      ],
      opts
    } = Keyword.split(benchmark_config, [:routes, :calls_per_cycle])

    routes = RouteGenerator.gen_routes num_routes, opts

    Generator.gen_router(Benchmark.Plug, :plug, routes)
    Generator.gen_router(Benchmark.Phoenix, :phoenix, routes)
    Generator.gen_router(Benchmark.Honeybee, :honeybee, routes)

    plugs = RouteGenerator.gen_plugs routes, num_plugs

    honeybee_opts = Benchmark.Honeybee.init([]);
    phoenix_opts = Benchmark.Phoenix.init([]);
    plug_opts = Benchmark.Plug.init([]);

    honeybee_call = fn -> Enum.each(plugs, &Benchmark.Honeybee.call(&1, honeybee_opts)) end
    phoenix_call = fn -> Enum.each(plugs, &Benchmark.Phoenix.call(&1, phoenix_opts)) end
    plug_call = fn -> Enum.each(plugs, &Benchmark.Plug.call(&1, plug_opts)) end

    Benchee.run(
      %{
        "Paug.Router" => plug_call,
        "Phoenix.Router" => phoenix_call,
        "ZHoneybee" => honeybee_call
      },
      formatters: [
        Benchee.Formatters.HTML,
        Benchee.Formatters.Console
      ],
      warmup: 5,
      time: 15
    )
  end
end
