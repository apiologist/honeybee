# Honeybee

## Disclaimer
The interface and specifics of the Honeybee API are subject to change throughout development toward version 1.0.0. Use of Honeybee in production environments can be a risk. Report any issues to the [IssueTracker](https://github.com/apiologist/honeybee/)

## What is Honeybee?
Honeybee is a router intended for microservice/SOA APIs. It can be seen as an extension of [Plug](https://hexdocs.pm/plug/readme.html).

Honeybee's key features / goals:
 - Easy to understand, Easy to read, Easy to write.
 - Small and fast.
 - Unopinionated.
 - Strict compile-time validations.

Honeybee builds further ontop of the plug interface. It takes inspiration from both the Plug router and the Phoenix router, taking the good from both routers, in an attempt to provide the best router API for building small performant scalable APIs. Honeybee offers a slim DSL for declaring routes as isolated plug pipelines. This allows developers to quickly develop versatile routers, and allows the developer to use any plug compatible libraries natively in the pipelines.

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
      plug Routes.Example, action: :static
    end

    get "/:id" do
      plug Routes.Example, action: :param
    end

    get "/hello*glob" do
      plug Routes.Example, action: :glob
    end

    get "/*glob" do
      plug Routes.Example, action: :glob
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
  use Honeybee.Handler

  def static(conn, _opts) do
    Plug.Conn.send_resp(conn, 200, "world")
  end

  def param(conn, _opts) do
    %{
      "id" => id
    } = conn.path_params

    Plug.Conn.send_resp(conn, 200, "Got " <> id)
  end

  def glob(conn, _opts) do
    %{
      "glob" => glob
    } = conn.path_params
  
    Plug.Conn.send_resp(conn, 200, "Globbing: " <> Enum.join(glob, "/"))
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

$ curl http://localhost:8080/examples/hello-world/whats-up
Globbing: -world/whats-up

$ curl http://localhost:8080/something/that/doesnt/exist
Not Found: /something/that/doesnt/exist
```

## Dependencies
Honeybee depends on [Plug](https://hexdocs.pm/plug/readme.html "Plug Hexdocs").

## Installation
Honeybee is installed by adding it to the dependencies of the mix.exs:

```
{
  {:plug_cowboy, "~> 2.0"},
  {:honeybee, "~> 0.3"}
}
```

I recommend using cowboy as a webserver, however that being said, any webserver compatible with the plug library will work using honeybee.

