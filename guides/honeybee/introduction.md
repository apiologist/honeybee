# Honeybee

## Alpha
This is an alpha build of Honeybee. Use in production environments is not advised.
Report any issues to the [IssueTracker](https://github.com/apiologist/honeybee/)

## What is Honeybee?
Honeybee is a router intended for microservice/SOA APIs. It can be seen as an extension of [Plug](https://hexdocs.pm/plug/readme.html).

Honeybee's key features:
 - Easy to understand, DRY syntax.
 - Strict compile-time validations.
 - Detailed, descriptive errors.
 - Performance (both compile-time and run-time).
 - Small package size with minimum bloat.
 - Unopinionated.

### Easy to understand
Honeybee provides a DSL for building feature rich routing.
The DSL is easy to read and understand,
while still being useful to developers.

The core concept of Honeybee is the pipeline.
Pipelines can be declared, reused and composed to avoid code repetition.
Each request defines a unique request pipeline.

### Strict compile-time validations
Honeybee will provide strict validation during compilation,
in order to inform the developer of potential problems as soon as possible.

### Detailed, descriptive errors
Honeybee will provide detailed and descriptive errors,
clearly showing line numbers and the cause of the error in the message.
This allows developer tools to highlight errors in the editor while the code is being written.

### Performance
Honeybee is the fastest router in the Elixir language (based on microbenchmarking), surpassing the performance of both the Plug and Phoenix routers.

Typical routing speeds of Honeybee is sub microsecond.

Benchmarking was done using [Benchee](https://hexdocs.pm/benchee/Benchee.html).
Benchmarking performance of a batch of 10 000 random requests onto 100 routes is shown.

![alt text](https://raw.githubusercontent.com/apiologist/honeybee/master/guides/assets/ips_plot.png "Benchmark of runs per second for 10 000 requests on 100 routes")

![alt text](https://raw.githubusercontent.com/apiologist/honeybee/master/guides/assets/runtime_plot.png "Benchmark of run time for 10 000 requests on 100 routes")

## Example
```
defmodule MyApp.MyRouter do
  use Honeybee

  scope "/examples" do
    get "/hello", do: plug MyApp.Example, call: :static_route
    get "/:id", do: plug MyApp.Example, call: :dynamic_route
    get "/static*glob", do: plug MyApp.Example, call: :mixed_route
    get "/*glob", do: plug MyApp.Example, call: :glob_route
  end

  match _, "/:*_not_found", do: plug MyApp.MyRouter, :not_found

  def not_found(%Plug.Conn{path: path} = conn, _opts) do
    Plug.Conn.resp(conn, 404, "Not Found: " <> #{path})
  end
end
```

```
defmodule MyApp.Example do
  def init(opts), do: Keyword.split!(opts, [:call])
  def call(conn, {[call: method], opts}) do
    apply(__MODULE__, method, [conn, opts])
  end

  def static_route(conn, _opts) do
    Plug.Conn.resp(conn, 200, "world")
  end

  def dynamic_route(%{path_params: {"id" => id}} = conn, _opts) do
    Plug.Conn.resp(conn, 200, "Got " <> id)
  end

  def glob_route(%{path_params: {"glob" => glob}} = conn, _opts) do
    Plug.Conn.resp(conn, 200, "Globbing: " <> Enum.join(glob, "/"))
  end

  def mixed_route(%{path_params: {"glob" => glob}} = conn, _opts) do
    Plug.Conn.resp(conn, 200, "Remaining: " <> Enum.join(glob, "/"))
  end
end
```

```bash
$ curl http://localhost:8080/examples/hello
world

$ curl http://localhost:8080/examples/10
Got 10

$ curl http://localhost:8080/examples/this/will/be/globbed
Globbing: this/will/be/globbed

$ curl http://localhost:8080/examples/staticsomething/else
Remaining: something/else

$ curl http://localhost:8080/something/that/doesnt/exist
Not Found: /something/that/doesnt/exist
```

## Dependencies
Honeybee depends on [Plug](https://hexdocs.pm/plug/readme.html "Plug Hexdocs").
