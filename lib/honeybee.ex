defmodule Honeybee do
  defmodule CompileError do
    use Honeybee.Utils.Error
  end

  @moduledoc """
  Defines a Honeybee router.

  Provides macros for routing http-requests.

  Hello world example:
  ```
    defmodule MyApplication.MyRouter do
      use Honeybee

      defmodule Handlers do
        def init(opts), do: opts
        def call(conn, opts), do: apply(Handlers, Keyword.fetch!(opts, :call), [conn, opts])

        def hello_world(conn, _opts) do
          IO.puts("Hello World!")
          conn
        end
      end

      get "/hello/world" do
        plug Handlers, call: :hello_world
    end
  ```

  Honeybee provides routing capabilities to Plug apps.
  It uses the concept of plug pipelines to provide a useful api to developers.
  Named plug pipelines can be declared using the `pipe/2` macro,
  and included in scoped pipelines with `using/1`.
  Scopes can be declared with `scope/2`.

  This allows each route to process a unique pipeline,
  in a way which is easy to read, easy to understand and easy to use.
  """
  use Honeybee.Utils.Types

  @routes  :__honeybee_routes__
  @scope   :__honeybee_scope__
  @pipes   :__honeybee_pipes__
  @context :__honeybee_context__
  @opts    :__honeybee_opts__

  defmacro __using__(opts \\ []) do
    env = __CALLER__
    Module.put_attribute(env.module, @opts, opts)
    Module.put_attribute(env.module, @context, :root)
    Module.put_attribute(env.module, @scope, [[line: env.line, path: "", using: []]])
    Module.register_attribute(env.module, @routes, accumulate: true)
    Module.register_attribute(env.module, @pipes, accumulate: true)

    quote do
      import Honeybee
      @behaviour Plug
      @before_compile Honeybee

      def init(opts), do: opts

      def call(conn, opts) do
        case Keyword.fetch(opts, :forward_with) do
          {:ok, path_key} ->
            %{ ^path_key => path } = conn.path_params
            dispatch(conn, path)
          :error ->
            dispatch(conn, conn.path_info)
        end
      end
    end
  end

  @spec __before_compile__(Macro.Env.t()) :: Macro.t()
  defmacro __before_compile__(env) do
    compiled_pipes = compile_pipes(env)
    compiled_routes = compile_routes(env)
    unmatched_capture =
      quote do
        def dispatch(%Elixir.Plug.Conn{method: method, path_info: path}, _) do
          raise "No matching route for request: " <> method <> " /" <> Enum.join(path, "/")
        end
      end

    compiled_pipes ++ compiled_routes ++ [unmatched_capture]
  end

  defp compile_routes(env) do
    Module.get_attribute(env.module, @routes)
    |> Enum.reverse()
    |> Enum.map(fn route ->
      scope_stack = Keyword.fetch!(route, :scope)

      pipes = scope_stack
        |> Enum.flat_map(&Keyword.fetch!(&1, :using))
        |> Enum.map(&{:call_pipe, &1, true})

      plugs = Keyword.fetch!(route, :plugs)

      {conn, compiled_pipeline} = Elixir.Plug.Builder.compile(
        env,
        plugs ++ pipes,
        Module.get_attribute(env.module, @opts)
      )

      scoped_path = Enum.reduce(scope_stack, "", &(Keyword.fetch!(&1, :path) <> &2))
      path = scoped_path <> Keyword.fetch!(route, :path)

      {pattern, params} = Honeybee.Utils.Path.compile(path)

      quote line: Keyword.fetch!(route, :line) do
        def dispatch(%Elixir.Plug.Conn{
          method: unquote(Keyword.fetch!(route, :method))
        } = unquote(conn), unquote(pattern)) do
          unquote(conn) = %Elixir.Plug.Conn{
            unquote(conn) | path_params: unquote(params)
          }
          unquote(compiled_pipeline)
        end
      end
    end)
  end

  defp compile_pipes(env) do
    Module.get_attribute(env.module, @pipes)
    |> Enum.map(fn pipe ->
      name = Keyword.fetch!(pipe, :name)
      plugs = Keyword.fetch!(pipe, :plugs)
      
      {conn, compiled_plugs} = Elixir.Plug.Builder.compile(
        env,
        plugs,
        Module.get_attribute(env.module, @opts)
      )
      
      quote line: Keyword.fetch!(pipe, :line) do
        defp call_pipe(unquote(conn), unquote(name)) do
          unquote(compiled_plugs)
        end
      end
    end)
  end

  @doc """
  An alias for `match "HEAD"`
  """
  @spec head(String.t(), term()) :: :ok
  defmacro head(path, do: block) when is_bitstring(path) do
    make_route(__CALLER__, "HEAD", path, block)
    nil
  end

  @doc """
  An alias for `match "GET"`
  """
  @spec get(String.t(), term()) :: :ok
  defmacro get(path, do: block) when is_bitstring(path) do
    make_route(__CALLER__, "GET", path, block)
    nil
  end

  @doc """
  An alias for `match "POST"`
  """
  @spec post(String.t(), term()) :: :ok
  defmacro post(path, do: block) when is_bitstring(path) do
    make_route(__CALLER__, "POST", path, block)
    nil
  end

  @doc """
  An alias for `match "PUT"`
  """
  @spec put(String.t(), term()) :: :ok
  defmacro put(path, do: block) when is_bitstring(path) do
    make_route(__CALLER__, "PUT", path, block)
    nil
  end

  @doc """
  An alias for `match "PATCH"`
  """
  @spec patch(String.t(), term()) :: :ok
  defmacro patch(path, do: block) when is_bitstring(path) do
    make_route(__CALLER__, "PATCH", path, block)
    nil
  end

  @doc """
  An alias for `match "CONNECT"`
  """
  @spec connect(String.t(), term()) :: :ok
  defmacro connect(path, do: block) when is_bitstring(path) do
    make_route(__CALLER__, "CONNECT", path, block)
    nil
  end

  @doc """
  An alias for `match "OPTIONS"`
  """
  @spec options(String.t(), term()) :: :ok
  defmacro options(path, do: block) when is_bitstring(path) do
    make_route(__CALLER__, "OPTIONS", path, block)
    nil
  end

  @doc """
  An alias for `match "DELETE"`
  """
  @spec delete(String.t(), term()) :: :ok
  defmacro delete(path, do: block) when is_bitstring(path) do
    make_route(__CALLER__, "DELETE", path, block)
    nil
  end

  @doc """
  Adds a route matching `http_method` requests on `path`, containing `plug_pipeline`.

  When an incoming request hits a Honeybee router,
  the router attempts to match the request against the routes defined in the router.
  The router will only invoke the first route that matches the incoming request.
  The priority of the route is determined by the order of the match statements in the router.

  When a match is made,
  the scoped pipelines for the route are invoked,
  then the route pipeline is invoked.

  Honeybee will always match exactly one route to the request.
  To provide a fallback route, use `match _, "*" do ... end`.
  Honeybee inserts a default fallback of this kind at the bottom of the route table which raises an error.

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
    defmodule ExampleApp.Router do
      use Honeybee

      get "/api/v1/examples/:id" do
        plug ExampleApp.Routes.Example, call: :get
      end
    end
    ```
  
  Using the match method to specify the same route as above.
    ```
    defmodule ExampleApp.Router do
      use Honeybee

      match "GET", "/api/v1/examples/:id" do
        plug ExampleApp.Routes.Example, call: :get
      end
    end
    ```
  """
  @spec match(String.t() | Var.t(), String.t(), term()) :: :ok
  defmacro match(http_method, path, plug_pipeline)
  defmacro match(method, path, do: block) when is_bitstring(path) do
    make_route(__CALLER__, method, path, block)
    nil
  end

  @doc """
  Declares an isolated scope with the provided `path`. 

  Scopes are used to encapsulate a block of routes and
  optionally provide a base path to any routes declared within.

  Calling `using/1` inside a scope adds pipes to the scoped pipeline.
  Scoped pipelines run prior to route pipelines upon a match.

  Scopes can be nested.

  ## Examples
  In the following example,
  an http request `"GET"` on `"/"` will invoke `RootHandler.call/2`.
  An http request `"GET"` on `"/api/v1"` will invoke `ExamplePlug.call/2`, `ExamplePlug2.call/2` and `V1Handler.call/2`

  ```
  defmodule ExampleApp.Router do
    use Honeybee
  
    pipe :example do
      plug ExamplePlug
      plug ExamplePlug2
    end
  
    scope "/api" do
      using :example
  
      get "/v1" do
        plug V1Handler, call: :get
      end
    end
  
    get "/" do
      plug RootHandler, call: :get
    end
  end
  ```
  """
  @spec scope(String.t(), term()) :: :ok
  defmacro scope(path \\ "", do: block) when is_bitstring(path) do
    make_scope(__CALLER__, path, block)
    nil
  end

  @doc """
  Declares a new pipe with `name`, containing `plug_pipeline`

  Plugs declared in the `plug_pipeline` are invoked in order when the pipe is part of a match.
  A pipe can be included in a scoped pipeline with `using/1`

  ## Examples
  ```
  pipe :example_pipe do
    plug :local_example1, some_options: :opt1
    plug PluggableExmapleModule 
  end
  ```
  """
  defmacro pipe(name, plug_pipeline)
  @spec pipe(atom(), term()) :: :ok
  defmacro pipe(name, do: block) when is_atom(name) do
    make_pipe(__CALLER__, name, block)
    nil
  end

  @doc """
  Adds `pipes` to the scoped pipeline.

  The provided pipes should be a list of atoms, corresponding the names of the pipes.
  A single atom can be provided as well.

  Routes declared prior will not be affected by a `using/1` statement.
  """
  defmacro using(pipes)
  @spec using([atom]) :: :ok
  defmacro using(pipes) when is_list(pipes) do
    make_using(__CALLER__, pipes)
    nil
  end

  @spec using(atom) :: :ok
  defmacro using(pipe) when is_atom(pipe) do
    make_using(__CALLER__, [pipe])
    nil
  end

  @doc """
    Declares a plug.

    For documentation regarding `plug/2` go to `Plug`
  """
  @spec plug(atom() | Alias.t(), keyword()) :: Honeybee.Plug.t()
  defmacro plug(plug, opts \\ []) do
    make_plug(__CALLER__, plug, opts)
  end

  defp make_route(env, method, path, block) do
    scope = Module.get_attribute(env.module, @scope)
    plugs = __expand_block__(env, :route, block)

    Module.put_attribute(env.module, @routes, [
      line: env.line,
      scope: scope,
      method: method,
      path: path,
      plugs: plugs
    ])
  end

  defp make_scope(env, path, block) do
    push_scope(env, path)
    __expand_block__(env, :scope, block)
    pop_scope(env)
  end

  defp make_pipe(env, name, block) do
    plugs = __expand_block__(env, :pipe, block)

    Module.put_attribute(env.module, @pipes, [
      line: env.line,
      name: name,
      plugs: plugs
    ])
  end

  defp make_using(env, pipes) do
    [top_scope | stack] = get_scope_stack(env)
    {_, top_scope} = Keyword.get_and_update!(top_scope, :using, &{nil, Enum.reverse(pipes) ++ &1})

    Module.put_attribute(env.module, @scope, [top_scope | stack])
  end

  defp make_plug(env, plug, opts, guards \\ true) do
    {plug, __resolve__(env, opts), guards}
  end

  defp push_scope(env, path, using \\ []) do
    Module.put_attribute(env.module, @scope, [
      [line: env.line, path: path, using: using]
      | get_scope_stack(env)
    ])
  end

  defp pop_scope(env) do
    [_ | scope] = get_scope_stack(env)
    Module.put_attribute(env.module, @scope, scope)
  end

  defp get_scope_stack(env) do
    Module.get_attribute(env.module, @scope)
  end

  defp __expand_block__(env, ctx, block) do
    outer_context = Module.get_attribute(env.module, @context)
    Module.put_attribute(env.module, @context, ctx)
    statements = __expand_block__(env, block)
    Module.put_attribute(env.module, @context, outer_context)
    statements
  end
  defp __expand_block__(env, {:__block__, _, statements}), do: __resolve__(env, statements)
  defp __expand_block__(env, statement), do: __resolve__(env, [statement])
  defp __resolve__(env, statements) when is_list(statements) do
    statements |> Macro.prewalk(&Macro.expand(&1, env)) |> Enum.reverse()
  end
  defp __resolve__(env, statement) do
    Macro.expand(statement, env)
  end
end
