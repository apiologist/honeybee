# What is Honeybee?
Honeybee is a router intended for RESTful APIs. It's built on [Plug](https://hexdocs.pm/plug/readme.html).

Honeybee's key features include:
 - Feature rich routing.
 - Strong compile time validation.
 - Detailed, descriptive errors.
 - Extreme speed.
 - Superior compile time performance.
 - Easy, DRY syntax.
 - Minimum bloat.
 - Unopinionated.

# Performance
Honeybee is one of the fastest routers in the Elixir language, easily surpassing the performance of both Plug and Phoenix routers. Typical routing speeds of Honeybee is 100-200 nanoseconds.

A benchmark measuring the performance of routing 10 000 requests on 100 route definitions is shown below.

![alt text](https://github.com/sfinnman/honeybee/blob/simon/initial-commit/guides/assets/ips_plot.png?raw=true "Benchmark of runs per second for 10 000 requests on 100 routes")

![alt text](https://github.com/sfinnman/honeybee/blob/simon/initial-commit/guides/assets/runtime_plot.png?raw=true "Benchmark of run time for 10 000 requests on 100 routes")

# Honeybee

## Example
```
defmodule MyApp.MyRouter do
  use Honeybee

  scope "/examples" do
    get "/hello", MyApp.Example, :static_route
    get "/:id", MyApp.Example, :dynamic_route
    get "/:*glob", MyApp.Example, :glob_route
    get "/static:*glob", MyApp.Example, :mixed_route
  end

  match _, "/:*_not_found", MyApp.MyRouter, :not_found

  def not_found(%Plug.Conn{path: path} = conn, _opts) do
    Plug.Conn.resp(conn, 404, "Not Found: " <> #{path})
  end
end
```

```
defmodule MyApp.Example do
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
Honeybee depends on [Plug](https://hexdocs.pm/plug/readme.html "Plug Hexdocs") and [Cowboy](https://github.com/ninenines/cowboy "Cowboy Github").

