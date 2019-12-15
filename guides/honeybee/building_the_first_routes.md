# Building the first routes
## Adding the first route
We start by adding the simplest possible route one could imagine. Yes, the classic hello world example, of course i have a hello world example! Here we are using the match macro, to build a route which will match any method request on `"/hello"`, and responding with `"hello world"`.

```
defmodule MyApp.Router do
  use Honeybee

  match _, "/hello", do: plug :world
  def world(conn, opts) do
    Plug.Conn.resp(conn, 200, "hello world")
  end

  match _, "*", do: plug :not_found
  def not_found(conn, _opts), do: Plug.Conn.resp(conn, 404, "")
end
```

## Creating a route module
Putting route logic in the router can become overwhelming after a while. When this approach is no longer viable we might want to separate the responsibility of routing and route-handling. Using this simple pattern creates a plug module which can hold route-handlers for us. We start by changing the route definition in the router to invoke an external plug module. Here we also add an alias for the Routes namespace.

```
defmodule MyApp.Router do
  use Honeybee
  alias MyApp.Routes

  match _, "/hello" do
    plug Routes.HelloWorld, handler: :hello_world
  end

  match _, "*", do: plug :not_found
  def not_found(conn, _opts), do: Plug.Conn.resp(conn, 404, "")
end
```

The router now routes the request for "/hello" to MyApp.Routes.HelloWorld plug module. This module includes a minimalistic plug setup, which attempts to call the requested handler when invoked. If you have a hard time understanding this pattern, i emplore you to explore the `Plug` docs, in which a plug module is documented in-depth. 

```
defmodule MyApp.Routes.HelloWorld do
  def init(opts), do: [
    Keyword.fetch!(opts, :handler),
    Keyword.get(opts, :opts, [])
  ]
  def call(conn, [handler, opts]) do
    apply(__MODULE__, handler, [conn, opts])
  end

  def hello_world(conn, _opts) do
    Plug.Conn.resp(conn, 200, "hello_world")
  end
end
```
## Adding a body parser
In most cases, unsafe methods, such as POST, PUT, PATCH etc. will include a body containing a payload of data, for which the handler will interact with. By default bodies are not parsed by the webserver, nor by honeybee. In order to access the body of the request in a meaningful way, the body must first be parsed. For this purpose we invoke the `Plug.Parsers` plug, which will parse the body of the incoming request, making it available for our handlers to use. In order for this to work, we must provide Plug.Parsers with a package which can parse JSON bodies (under the assumption that the api we are building is a JSON api.). My suggestion for such modules will be either `Poison` or `Jason`, but any module with JSON-parsing capabilities will do.

In this example the placement of the body parser plug is not of much importance, we can place it either in the router or the entrypoint, however a performance case can be made for moving the body-parser into any route handler which actually needs to parse the body. 

```
defmodule MyApp.Router do
  use Honeybee
  alias MyApp.Routes

  plug Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Poison

  match _, "/hello" do
    plug Routes.HelloWorld, handler: :hello_world
  end

  match _, "*", do: plug :not_found
  def not_found(conn, _opts), do: Plug.Conn.resp(conn, 404, "")
end
```

## Adding an admin scope
In this example we are exploring the scope capabilities of the `Honeybee` router. A scope, much like function scopes, is an isolated environment. In a scope, any plugs we define are isolated to that scope, and any scopes nested inside it. This is a powerful tool for when we start adding routes which share some common requirements, such as authorized routes. Scopes can be declared either just for isolation, but also to give any nested route a common base path.

In the router below we have added a scope, inside of which we have declared an Authorization plug.

```
defmodule MyApp.Router do
  use Honeybee
  alias MyApp.Routes

  plug Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Poison

  scope do
    plug MyApp.Authorization, level: :admin

    get "/users" do
      plug Routes.Users, handler: :get_users
    end
  end

  match _, "*", do: plug :not_found
  def not_found(conn, _opts), do: Plug.Conn.resp(conn, 404, "")
end
```

## Route specific plugs
You may have been wondering about why we declare our route plug inside a do block. This is because every route is itself a Plug.Builder style pipeline (It's actually compiled using Plug.Builder under the hood.). This style allows us to put much of boilerplate handling out of our route handlers, and in to seperate pluggable modules. This pattern makes the router module much, much more transparent. Things that usually go in to a route pipeline can be Authorization, Validation or prefetching resources.

```
defmodule MyApp.Router do
  use Honeybee
  alias MyApp.Routes

  plug Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Poison

  scope do
    plug Authorization, level: :admin

    get "/users" do
      plug Routes.Users, handler: :get_users
    end

    post "/users" do
      plug Validators.Users, validate: :create_user
      plug Routes.Users, handler: :create_user
    end
  end

  match _, "*", do: plug :not_found
  def not_found(conn, _opts), do: Plug.Conn.resp(conn, 404, "")
end
```

## Forwarding to another router
As a preface to this section, please use forwarding sparringly. Usually scopes will cover most of the cases one would normally forward. That being said lets take a look at forwarding in Honeybee. Surprise! Forwarding is just plugging a router into a router. Providing the plug option `:forward_with` to target a globbed path, will forward the request to the next router on that path. Note that when forwarding, the router being forwarded to not resolve the full path of the request.

```
defmodule MyApp.MyApi.MyRouter do
  use Honeybee
  plug Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Poison

  match _, "/users/*forward_path" do
    plug MyApp.UserRouter, forward_with: "forward_path"
  end

  match _, "*", do: plug :not_found
  def not_found(conn, _opts), do: Plug.Conn.resp(conn, 404, "")
end
```
