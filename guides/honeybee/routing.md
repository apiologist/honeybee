# Getting started

## Installation
Honeybee is installed by adding it to the dependencies of the mix.exs:

```
{
  {:plug_cowboy, "~> 2.0"},
  {:honeybee, "~> 0.2.1"}
}
```

`:plug_cowboy` includes both plug and Cowboy. Cowboy is a popular webserver, used by most elixir api's.

## Setting up the webserver
The webserver is part of your application, and serves as an entrypoint to the application.

```
defmodule MyApp do
  use Supervisor

  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(scheme: :http, plug: MyApp.MyApi, options: [port: 8080])
    ]
    
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

## Setting up the api request pipeline
Incoming requests will processed by the plug specified in the child_spec of the webserver.
Here we use a `Plug.Builder` to build a simple pipeline that will process all incoming requests.
At the end we pipe the connection to the router.

```
defmodule MyApp.MyApi do
  use Plug.Builder

  plug Plug.Logger
  plug Plug.MethodOverride
  plug Plug.Head

  plug MyApp.MyApi.MyRouter
end
```

## Setting up the router
In the router we provide a basic route scheme that will respond 404 to all incoming requests.

```
defmodule MyApp.MyApi.MyRouter do
  use Honeybee

  match _, "*", do: plug :not_found
  
  def not_found(conn, _opts) do
    Plug.Conn.resp(conn, 404, "")
  end
end
```

## Adding the first route
The app should respond `"hello world"` to all requests on the path `"/knock/knock"`.
We add a route to provide this functionality

```
defmodule MyApp.MyApi.MyRouter do
  use Honeybee

  match _, "/knock/knock", do: plug :hello_world

  match _, "*", do: plug :not_found

  def hello_world(conn, _opts), do: Plug.Conn.resp(conn, 200, "hello world")
  def not_found(conn, _opts), do: Plug.Conn.resp(conn, 404, "")
end
```

## Creating a route module
Putting route logic in the router can become overwhelming after a while.
When this approach is no longer viable we might want to separate responsibility of routing and handling.
We can use a simple pattern to create a module that handles connections for us.

```
defmodule MyApp.MyApi.MyFirstRouteHandler do
  def init(opts), do: Keyword.split(opts, [:handler])
  def call(conn, {[handler: method], opts}) do
    apply(__MODULE__, method, [conn, opts])
  end

  def hello_world(conn, _opts) do
    Plug.Conn.resp(conn, 200, "hello_world")
  end
end
```

Our router will now look like this

```
defmodule MyApp.MyApi.MyRouter do
  use Honeybee

  match _, "/knock/knock", do: plug MyApp.MyApi.MyFirstRouteHandler, handler: :hello_world

  match _, "*", do: plug :not_found
  def not_found(conn, _opts), do: Plug.Conn.resp(conn, 404, "")
end
```

## Adding a body parser
Many handlers will need access to the body of the request.
Plug has a pluggable module which can be added to the request pipeline in order to parse request bodies.

```
defmodule MyApp.MyApi.MyRouter do
  use Honeybee

  plug Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Poison

  match _, "/knock/knock", do: plug MyApp.MyApi.MyFirstRouteHandler, handler: :hello_world

  match _, "*", do: plug :not_found
  def not_found(conn, _opts), do: Plug.Conn.resp(conn, 404, "")
end
```

## Adding an admin scope
Some routes should not be accessed by unauthorized users.
In this example we will add a scope which validates requests on all routes.

```
defmodule MyApp.MyApi.MyRouter do
  use Honeybee

  plug Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Poison

  scope do
    plug Authorization, level: :admin

    get "/users", do: plug MyApp.MyApi.MyFirstRouteHandler, handler: :get_users
  end

  match _, "/knock/knock", do: plug MyApp.MyApi.MyFirstRouteHandler, handler: :hello_world

  match _, "*", do: plug :not_found
  def not_found(conn, _opts), do: Plug.Conn.resp(conn, 404, "")
end
```

## Route specific plugs
Route specific plugs can be added to plug block of the route.
This can be seen below in the `"knock/knock"` route.

```
defmodule MyApp.MyApi.MyRouter do
  use Honeybee

  plug Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Poison

  scope do
    plug Authorization, level: :admin

    get "/users", do: plug MyApp.MyApi.MyFirstRouteHandler, handler: :get_users
  end

  match _, "/knock/knock", do
    plug MyApp.MyApi.Validators, handler: :hello_world
    plug MyApp.MyApi.MyFirstRouteHandler, handler: :hello_world
  end

  match _, "*", do: plug :not_found
  def not_found(conn, _opts), do: Plug.Conn.resp(conn, 404, "")
end
```

## Forwarding to another router
Forwarding is an important part of routing.
This behaviour is modelled in Honeybee using the `:forward_with` option to a router.

Below is an example of forwarding in a Honeybee router.

```
defmodule MyApp.MyApi.MyRouter do
  use Honeybee

  match _, "/forward/*forward_path" do
    plug MySecondRouter, forward_with: "forward_path"
  end

  plug Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Poison

  scope do
    plug Authorization, level: :admin

    get "/users", do: plug MyApp.MyApi.MyFirstRouteHandler, handler: :get_users
  end

  match _, "/knock/knock", do
    plug MyApp.MyApi.Validators, handler: :hello_world
    plug MyApp.MyApi.MyFirstRouteHandler, handler: :hello_world
  end

  match _, "*", do: plug :not_found
  def not_found(conn, _opts), do: Plug.Conn.resp(conn, 404, "")
end
```

