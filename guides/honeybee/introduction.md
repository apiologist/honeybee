# Honeybee

## Alpha
This is an alpha build of Honeybee. Use in production environments is not advised.
Report any issues to the [IssueTracker](https://github.com/apiologist/honeybee/)

## What is Honeybee?
Honeybee is a router intended for microservice/SOA APIs. It can be seen as an extension of [Plug](https://hexdocs.pm/plug/readme.html).

Honeybee's key features / goals:
 - Easy to understand, Easy to read, Easy to write.
 - Small and fast.
 - Unopinionated.
 - Strict compile-time validations.

Honeybee builds further ontop of the plug interface. It takes inspiration from both the Plug router and the Phoenix router, taking the good from both routers, in an attempt to provide the best router API for building small performant scalable APIs. Honeybee offers a slim DSL for declaring routes as seperate route pipelines. This allows developers to quickly develop versatile routers, and does not impose the use of other libraries in the process.

### Performance
Honeybee is the fastest router in the Elixir language (based on microbenchmarking), surpassing the performance of both the Plug and Phoenix routers.

Typical routing speeds of Honeybee are in the sub microsecond range.

Benchmarking was done using [Benchee](https://hexdocs.pm/benchee/Benchee.html).
Benchmarking performance of a batch of 10 000 random requests onto 100 routes is shown.

![alt text](https://raw.githubusercontent.com/apiologist/honeybee/master/guides/assets/ips_plot.png "Benchmark of runs per second for 10 000 requests on 100 routes")

![alt text](https://raw.githubusercontent.com/apiologist/honeybee/master/guides/assets/runtime_plot.png "Benchmark of run time for 10 000 requests on 100 routes")

## Example
```
defmodule MyApp.MyRouter do
  use Honeybee
  alias MyApp.Routes

  scope "/examples" do
    get "/hello" do
      plug Routes.Example, handler: :static_route
    end

    get "/:id" do
      plug Routes.Example, handler: :dynamic_route
    end

    get "/static*glob" do
      plug Routes.Example, handler: :mixed_route
    end

    get "/*glob" do
      plug Routes.Example, handler: :glob_route
    end
  end

  match _, "*", do: plug :not_found
  def not_found(%Plug.Conn{path: path} = conn, _opts) do
    Plug.Conn.send_resp(conn, 404, "Not Found: " <> #{path})
  end
end
```

```
defmodule MyApp.Routes.Example do
  def init(opts), do: [
    Keyword.fetch!(opts, :handler),
    Keyword.fetch!(opts, :opts)
  ]
  def call(conn, [method, opts]) do
    apply(__MODULE__, method, [conn, opts])
  end

  def static_route(conn, _opts) do
    Plug.Conn.resp(conn, 200, "world")
  end

  def dynamic_route(conn, _opts) do
    %{
      "id" => id
    } = conn.path_params

    Plug.Conn.resp(conn, 200, "Got " <> id)
  end

  def glob_route(conn, _opts) do
    %{
      "glob" => glob
    } = conn.path_params
  
    Plug.Conn.resp(conn, 200, "Globbing: " <> Enum.join(glob, "/"))
  end

  def mixed_route(conn, _opts) do
    %{
      "glob" => glob
    } = conn.path_params

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
