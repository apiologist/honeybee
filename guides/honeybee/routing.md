# Routing
The Honeybee router syntax is very similar to the router of phoenix apart from some key things.

 - Honeybee doesn't assume the names of methods in request handlers, giving the developer the freedom to name handler methods however the developer sees fit.
 - Honeybee doesn't force imports down your throat. Maybe you want to name your functions whatever you like.
 - Honeybee has much stronger compile time error checking, letting developers spot routing errors early.
 - Honeybee is 15x faster than the Phoenix router and 7x faster than the Plug router.
 - Honeybee provides 0 magic apart from routing, it does not assume to know what JSON parser is best for your needs.
 - Honeybee is less than 1 MB in size, which is more than 60x smaller than Phoenix.
 - Honeybee compiles 6x faster than Phoenix and more than 30x faster than plug.

## Getting started
Start by adding the following dependencies to your app

```
{
  {:plug_cowboy, "~> 2.0"},
  {:honeybee, "~> 0.1.0"}
}
```

The `:plug_cowboy` dependency has Cowboy in it, which is an http/https server.
Lets start Cowboy with an Api plug.

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

```
defmodule MyApp.MyApi do
  use Plug.Builder

  plug Plug.Logger
  plug Plug.MethodOverride
  plug Plug.Head

  plug MyApp.MyApi.MyRouter
end
```

```
defmodule MyApp.MyApi.MyRouter do
  use Honeybee

  match _, MyApp.MyApi.NotFoundHandler, :not_found
end
```

```
defmodule MyApp.MyApi.NotFoundHandler do
  def not_found(conn, []) do
    Plug.Conn.resp(conn, 404, "")
  end
end
```


