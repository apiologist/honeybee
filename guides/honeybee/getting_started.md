# Getting Started
The first part we will build is an entrypoint to the api. The entrypoint serves as the gateway for all requests. Any request to the webserver will run the code specified in the entrypoint. Examples of things one might put in an entrypoint include: Body Parsing, Cors handling, Https redirects, Authorization etc. In the entrypoint we will put an entry to direct requests to our router (more on that one later). The router is what will direct requests to the requested resource or action.

## Setting up the entrypoint
The entrypoint is built using the `Plug.Builder`. `Plug.Builder` is a useful module for building so called request pipelines. A request pipeline is a list of static definitions of operations to apply to a request, and can include some of the things stated in the prelude above. The primary directive of the `Plug` module is the macro `Plug.plug/1`, which is used to declare an operation in a pipeline.

The following is the entrypoint, below is an explanation of what each of these operations do:
 - The `Plug.Logger` module logs metadata about incoming requests.
 - The `Plug.MethodOverride` module overrides a POST requests method, if another method is specified in the _method header of the request.
 - The `Plug.Head` module overrides HEAD requests to GET requests.
 - The last plug directs requests into the Router of our app.

```
defmodule MyApp.Entrypoint do
  use Plug.Builder

  plug Plug.Logger
  plug Plug.MethodOverride
  plug Plug.Head

  plug MyApp.Router
end
```

## Setting up the webserver
The webserver is the application we will be running. In effect, this will be what is running our API, listening for incoming requests from the internet. Setup is fairly straightforward and consists mostly of configuration. The configuration we have set tells the webserver to listen for HTTP requests on port 8080, and direct them to our entrypoint.

```
defmodule MyApp.WebServer do
  use Supervisor

  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(scheme: :http, plug: MyApp.Entrypoint, options: [port: 8080])
    ]
    
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

## Starting the webserver with mix.
Adding the following to our mix.exs will start the webserver by running the command `mix` in the command-line. We add logger as an additionational application, otherwise `Plug.Logger` will not function properly.

```
  def application do
    [
      mod: {Tavernan.Application, []},
      extra_applications: [:logger]
    ]
  end
```

## Setting up the router
Honeybee is a router package. In the router we will be declaring a honeybee router. This is done using the `Honeybee` module. Honeybee introduces a DSL for declaring routes. Each route can declare a unique plug pipeline, similar to the pipelines declared in `Plug.Builder`. Honeybee however provides us with the possibility to customize pipelines seperately for each route, thus being able to invoke custom behaviour on each route. The honeybee router itself is a plug, which is why we can invoke it as a plug from the entrypoint. You can find details about the Honeybee DSL in the `Honeybee` module docs. The router definition below is very bare bones, and will serve a 404 to any incoming request. As an exercise we will fill this router with more routes in the following sections, as well as providing meaningful patterns for building more routes.

```
defmodule MyApp.Router do
  use Honeybee

  match _, "*", do: plug :not_found
  
  def not_found(conn, _opts) do
    Plug.Conn.resp(conn, 404, "")
  end
end
```