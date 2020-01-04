defmodule Honeybee do
  @moduledoc """
  A `Honeybee` router provides a DSL (Domain specific language) for defining http routes and pipelines.
  Using Honeybee inside a module will make that module pluggable.
  When called The module will attempt to match the incoming request to the routes defined inside the router.

  Calling the router module is done either via a plug or by invoking `call/2`.

  Hello world example:
  ```
    defmodule Handlers do
      use Honeybee.Handler

      def hello_world(conn, _opts) do
        Plug.Conn.send_resp(conn, 200, "Hello World")
      end
    end

    defmodule MyApp.Router do
      use Honeybee

      get "/hello/world", do plug Handlers, action: :hello_world
    end
  ```

  ## Principals
  `Honeybee` reuses many patterns from `Plug.Builder`.
  In fact `Honeybee` uses `Plug.Builder` under the hood to compile all routes and pipelines.

  Since this pattern is quite ubiquitous among many plug packages, `Honeybee` has quite a shallow learning curve.

  `Honeybee` is performant, small and versatile, allowing developers to quickly write sustainable, readable and maintainable routing patterns.
  It makes no assumptions about what you are trying to build, or how you and your team wants to build it, by providing many different ways of implementing the router structure.
  This allows teams to decide internally what patterns to use and what conventions to follow.

  ## HTTP Routes
  Honeybee provides ten macros which can be used to define a route.
  The most fundamental macro of these, is the `match/3` macro.

  `match/3` expects to be called with HTTP-verb, a path string, and a plug pipeline.
  ```
  match "GET", "/users" do
    plug Routes.Users, action: :list_users
  end
  ```

  In order to match any HTTP-verb you can use the `_` operator instead of providing a verb.
  ```
  match _, "/users" do
    plug Routes.Users, action: :request
  end
  ```

  `match/3` also supports path parameter (`:`) and path globbing (`*`)
  ```
  match _, "/users/:id/*glob" do
    plug Routes.Users, action: :request
  end
  ```

  In addition to the `match/3` macro, a couple of shorthands exist for common HTTP-verbs.
   - `head/2`
   - `get/2`
   - `put/2`
   - `post/2`
   - `patch/2`
   - `delete/2`
   - `options/2`
   - `connect/2`

  Each of the above macros prefill the first argument of `match/3` and work otherwise the exact same
  ```
  get "/users/:id" do
    plug Routes.Users, action: :get_user
  end
  ```

  When a Honeybee router is called, only **one** single route can be matched.
  Routes are also defined in the order they are written.

  ## Plugs
  The `plug/2` macro can be used to declare a plug in the plug pipeline.
  `Honeybee` supports plugs similar to the `Plug.Builder`, however there are a couple of caveats.

  Plugs can be declared pretty much anywhere inside the module.
  They are not required to exist inside the `match/3` pipeline.
  Defining a plug outside of a route will prepend the plug to the pipelines of all routes which are defined **after** the invokation of the `plug/2` macro.

  `plug/2` also has guard support, which allows us to guard for the method of the incoming request.
  This allows you to write plugs which only apply to certain http-verbs of requests.

  ```
  plug BodyParser when method in ["POST", "PUT", "PATCH"]
  ```

  ## Scopes
  `Honeybee` has scope support, similar to how the `Phoenix.Router` supports scopes.
  Scopes are used to create isolation for routes, and also optionally accepts a basepath, which is appended to any route nested inside it.
  Isolation in this context means that, any plugs declared inside the scope only apply to routes declared inside the scope.

  The `scope/1` or `scope/2` macros can be used to define a scope.
  ```
  scope "/users" do
    plug Authorization, level: :admin

    get "/:id" do
      plug Routes.Users, action: :get_user
    end
  end

  # The authorization plug is not active outside the scope.
  ```

  ## Compositions
  `Honeybee` includes a special macro dedicated to building runtime pipelines which is the `composition/2` macro.
  This macro allows us to write very versatile inline pipelines, similar to the `pipeline/2` macro of the `Phoenix.Router`.

  The main difference is that, inside compositions, plugs can modify the options which the composition was called with.
  This allows us to provide options to many plugs in a single call, reducing the amount of these kind of pipelines we need.

  A composition will create a named private function in the router module.
  The name of this function will be the name we give the composition.
  This pattern allows us to use our composition as a plug, by its name.

  ```
  composition :auth do
    plug MyApp.JWT.Verifier, Keyword.get(opts, :jwt, [header: "authorization"])
    plug MyApp.Authorization, Keyword.get(opts, :auth, [level: :user])
  end

  scope do
    plug :auth, jwt: [header: "x_authorization"], auth: [level: :admin]

    post "/users" do
      plug Routes.Users, action: :create_user
    end
  end
  ```

  ## No Match
  Some requests will not match any route of the router.
  The default behaviour for `Honeybee` in such cases is to simply return the conn unmodified.

  To override this behaviour, simply define the function `no_match/2` in the router module, and do as you wish.

  ```
  def no_match(conn, _opts) do
    Plug.Conn.send_resp(conn, 404, "The requested route does not exist")
  end
  ```

  ## Forwarding
  In order to forward to another Honeybee router, using part of the original requested path, the :match option can be used when plugging to that router.
  The :match option is expected to contain the name of the path glob which should be used when matching in the forwarded router.

  ```
  match _, "/users/*user_request_path" do
    plug UserRouter, match: "user_request_path"
  end
  ```
  """

  @doc false
  defmacro __using__(_opts \\ []) do
    quote do
      @behaviour Plug
      import Honeybee

      def init(opts), do: opts
      def call(conn, opts) do
        case Keyword.fetch(opts, :match) do
          {:ok, key} -> %Elixir.Plug.Conn{
            honeybee_call(%Elixir.Plug.Conn{conn | path_info: conn.path_params[key]}, opts)
            | path_info: conn.path_info
          }
          :error -> honeybee_call(conn, opts)
        end
      end
      def no_match(conn, _opts), do: conn

      defoverridable [init: 1, call: 2, no_match: 2]

      Module.register_attribute(__MODULE__, :path, accumulate: false)
      Module.register_attribute(__MODULE__, :context, accumulate: false)
      Module.register_attribute(__MODULE__, :plugs, accumulate: false)
      Module.register_attribute(__MODULE__, :compositions, accumulate: true)
      Module.register_attribute(__MODULE__, :routes, accumulate: true)

      @path ""
      @plugs []
      @context :root

      @before_compile Honeybee
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    compiled_compositions = compile_compositions(env)
    compiled_routes = compile_routes(env)

    quote do
      unquote(compiled_compositions)
      unquote(compiled_routes)
      def honeybee_call(conn, opts), do: no_match(conn, opts)
      def compositions(), do: @compositions
      def routes(), do: @routes
    end
  end

  @doc false
  defp compile_routes(env) do
    Module.get_attribute(env.module, :routes)
    |> Enum.reduce([], fn ({method, path, plugs}, acc) ->
      {conn, body} = Plug.Builder.compile(env, plugs, [])
      {path_pattern, path_params} = Honeybee.Utils.Path.compile(path)

      compiled_route = quote do
        def honeybee_call(%Elixir.Plug.Conn{
          method: unquote(method) = unquote({:method, [generated: true], nil}),
          path_info: unquote(path_pattern)
        } = unquote(conn), _opts) do
          unquote(conn) = %Elixir.Plug.Conn{
            unquote(conn) | path_params: unquote(path_params)
          }
          unquote(body)
        end
      end

      [compiled_route | acc]
    end)
  end

  @doc false
  defp compile_compositions(env) do
    Module.get_attribute(env.module, :compositions)
    |> Enum.reduce([], fn ({name, plugs}, acc) ->
      plugs = Enum.map(plugs, fn
        {plug, opts, guards} -> {plug, {:unquote, [], [opts]}, guards}
      end)

      {conn, body} = Plug.Builder.compile(env, plugs, [init_mode: :runtime])

      compiled_composition = quote do
        def unquote(name)(%Elixir.Plug.Conn{
          method: unquote({:method, [generated: true], nil})
        } = unquote(conn), unquote({:opts, [generated: true], nil})) do
          unquote(body)
        end
      end

      [compiled_composition | acc]
    end)
  end

  @doc """
  Defines a named composition, which can be invoked using `plug/2`

  Compositions allow you to compose plug pipelines in-place.
  `composition/2` uses `Plug.Builder` under the hood to construct a private function which can be called using plug.

  Inside compositions, the `opts` variable is available.
  The `opts` var contains the options with which the composition was plugged.
  Inside the composition you can manipulate the opts variable however you like.

  Currently compositions evaluate options runtime, which can be very slow when composed plugs have expensive `init/1` methods.
  In such cases, consider not using the composition method.

  In a future release an option might be provided to resolve options compile-time.

  ## Examples
  ```
  composition :example do
    plug :local_plug, Keyword.take(opts, [:action])
    plug PluggableExmapleModule, Keyword.fetch!(opts, :example_opts)
  end
  ```
  """
  @spec composition(atom(), term()) :: term()
  defmacro composition(name, plug_pipeline)
  defmacro composition(name, do: block) when is_atom(name) do
    run_in_scope(quote do
      case @context do
        :root ->
          @context :composition
          @plugs []
          var!(opts) = {:opts, [], nil}
          unquote(block)
          @compositions {unquote(name), @plugs}
        _ -> raise "Cannot define a composition when not in the root scope"
      end
    end)
  end

  @verbs [head: "HEAD", get: "GET", put: "PUT", post: "POST", patch: "PATCH", options: "OPTIONS", delete: "DELETE", connect: "CONNECT"]
  for {name, verb} <- @verbs do
    @doc """
    An alias for `match "#{verb}"`

    See `match/3` for details
    """
    defmacro unquote(name)(path, do: block) when is_bitstring(path), do: put_route(unquote(verb), path, block)
  end

  @doc """
  Adds a route matching `http_method` requests on `path`, containing `plug_pipeline`.

  When an incoming request hits a Honeybee router,
  the router attempts to match the request against the routes defined in the router.
  The router will only invoke the first route that matches the incoming request.
  The priority of the route is determined by the order of the match statements in the router.
  When a match is made, the scoped pipelines for the route are invoked, then the route pipeline is invoked.

  ### Method
  The `http_method` can be any of the following literals:
   - `"HEAD"` (`head/2`)
   - `"GET"` (`get/2`)
   - `"POST"` (`post/2`)
   - `"PUT"` (`put/2`)
   - `"PATCH"` (`patch/2`)
   - `"CONNECT"` (`connect/2`)
   - `"OPTIONS"` (`options/2`)
   - `"DELETE"` (`delete/2`)

  For each method literal, a shorthand method exists (see above.)
  `http_method` can also be a pattern, for example `_` will match any http method.

  Guards are currently not supported, but may receive support in future versions of Honeybee.

  ### Path
  `path` is a pattern used to match incoming requests.

  Paths can be any string literal, and also have parameter and glob support.
  All parameters and globs are named.
  Resolved parameters and globs are available using their name as key
  in the `:path_params` map in the `Plug.Conn` struct.

  A path parameter is declared using `":"` and a path glob is declared using `"*"`

  `"/api/v1/examples/:id"` will match requests of the form `"/api/v1/examples/1"`,
  resulting in `%Plug.Conn{path_params: %{ "id" => "1" }}`.

  `"/api/v1/examples/*glob"` will match requests of the form `"/api/v1/examples/something/somethingelse"`,
  resulting in `%Plug.Conn{path_params: %{ "glob" => ["something", "somethingelse"] }}`

  Glob and variable matches can be used in combination, for example `"/api/v1/examples/:id/*glob"`.
  They can also be applied on partial strings such as `"/api/v1/examples/example-id-:id/example-*glob"`

  Since globs match the remainder of the requested path, nothing further can be matched after specifying a glob.

  Path parameters are available to the plugs of the scoped pipeline as well as the route pipeline.

  ### Plug pipeline
  The `plug_pipeline` contains the route pipeline, declared as a do-block of plugs.
  Plugs in the route pipeline are invoked in order.

  ## Examples
  Using the get method to specify a route.
  ```
    get "/api/v1/examples/:id" do
      plug Routes.Example, action: :get
    end
  ```

  Using the match method to specify the same route as above.
  ```
    match "GET", "/api/v1/examples/:id" do
      plug Routes.Example, action: :get
    end
  end
  ```
  """
  @spec match(String.t() | Var.t(), String.t(), term()) :: term()
  defmacro match(http_method, path, plug_pipeline)
  defmacro match(method, path, do: stmts) when is_binary(path), do: put_route(method, path, stmts)

  defp put_route(method, path, plugs) do
    run_in_scope(quote do
      case @context do
        ctx when ctx in [:root, :scope] ->
          @context :route
          unquote(plugs)
          @routes {unquote(Macro.escape(method)), @path <> unquote(path), @plugs}
        _ -> raise "Cannot define routes in any other context than scopes"
      end
    end)
  end

  @doc """
  Declares a plug.

  The `plug/2` macro can be used to declare a plug in the plug pipeline.
  `Honeybee` supports plugs similar to the `Plug.Builder`, however there are a couple of caveats.

  Plugs can be declared pretty much anywhere inside the module.
  Defining a plug outside of a route will prepend the plug to the pipelines of all routes which are defined **after** the invokation of the `plug/2` macro.

  `plug/2` also has guard support, which allows us to guard for the method of the incoming request.
  This allows you to write plugs which only apply to certain http-verbs of requests.

  ```
  plug BodyParser when method in ["POST", "PUT", "PATCH"]
  ```

  For more information on the plug pattern see `Plug`
  """
  @spec plug(atom(), term()) :: term()
  defmacro plug(plug, opts \\ [])
  defmacro plug({:when, _, [plug, guards]}, opts), do: gen_plug(__CALLER__, plug, opts, guards)
  defmacro plug(plug, {:when, _, [opts, guards]}), do: gen_plug(__CALLER__, plug, opts, guards)
  defmacro plug(plug, opts), do: gen_plug(__CALLER__, plug, opts, true)

  defp gen_plug(env, plug, opts, guards) do
    plug = Macro.expand(plug, %{env | function: {:init, 1}})

    quote do
      case @context do
        :composition -> @plugs [{unquote(plug), unquote(Macro.escape(opts)), unquote(Macro.escape(guards))} | @plugs]
        _ -> @plugs [{unquote(plug), unquote(opts), unquote(Macro.escape(guards))} | @plugs]
      end
    end
  end

  @doc """
  Declares an isolated scope with the provided `path`.

  Scopes are used to encapsulate and isolate any enclosed routes and plugs.
  Calling `plug/2` inside a scope will not affect any routes declared outside that scope.

  Scopes take an optional base path as the first argument.
  Honeybee wraps the top level of the module in whats known as the root scope.
  Scopes can be nested.

  ## Examples
  In the following example,
  The request `"GET" "/"` will invoke `RootHandler.call/2`.
  The request `"GET" "/api/v1"` will invoke `ExamplePlug.call/2` followed by `V1Handler.call/2`

  ```
  scope "/api" do
    plug ExamplePlug

    get "/v1" do
      plug V1Handler, action: :get
    end
  end

  get "/" do
    plug RootHandler, action: :get
  end
  ```
  """
  @spec scope(String.t(), term()) :: term()
  defmacro scope(path \\ "/", plug_pipeline)
  defmacro scope(path, do: stmts) when is_binary(path) do
    run_in_scope(quote do
      case @context do
        ctx when ctx in [:root, :scope] ->
          @context :scope
          @path @path <> unquote(path)
          unquote(stmts)
        _ -> raise "Cannot define scopes inside anything other contexts than inside a scope or the root context"
      end
    end)
  end

  @doc false
  defp run_in_scope(quoted_stmts) do
    quote generated: true do
      with(
        outer_plugs = @plugs,
        outer_path = @path,
        outer_context = @context
      ) do
        unquote(quoted_stmts)
        @plugs outer_plugs
        @path outer_path
        @context outer_context
      end
    end
  end
end
