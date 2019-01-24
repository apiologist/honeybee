defmodule Honeybee do
  @moduledoc """
  Defines a Honeybee router.

  Provides macros for routing http-requests.
  ```
    defmodule MyApplication.MyRouter do
      use Honeybee

      get "/hello/world", MyApplication.Greeter, :hello_world
    end
  ```
  Pinging Honeybee, `GET http://www.example.com/hello/world`, would invoke `MyApplication.Greeter.hello_world(%Plug.Conn{method: "GET", path_info: ["hello", "world"]})`

  ## Why Honeybee?
  Honeybee provides a router, very similar to the Phoenix Router, but is much smaller in size, less opionated and provides faster router and clearer errors.
  **It's perfect for RESTful APIs**.

  #
  """
  use Honeybee.Utils.Types

  alias Honeybee.Plug
  alias Honeybee.Scope
  alias Honeybee.Route
  alias Honeybee.Pipeline
  alias Honeybee.PipeThrough
  alias Honeybee.Compiler

  defmacro __using__(_ \\ []) do
    env = __CALLER__
    Scope.init(env)
    Route.init(env)
    Pipeline.init(env)

    quote do
      import Honeybee
      @before_compile Honeybee

      def init(opts), do: opts

      def call(conn, opts),
        do: dispatch(conn, Keyword.get(opts, :match_route, conn.path_info))
    end
  end

  @spec head(String.t(), Alias.t(), atom(), keyword()) :: :ok
  defmacro head(path, module, method, opts \\ []) do
    __match__(__CALLER__, "HEAD", path, module, method, opts)
  end

  @spec get(String.t(), Alias.t(), atom(), keyword()) :: :ok
  defmacro get(path, module, method, opts \\ []) do
    __match__(__CALLER__, "GET", path, module, method, opts)
  end

  @spec post(String.t(), Alias.t(), atom(), keyword()) :: :ok
  defmacro post(path, module, method, opts \\ []) do
    __match__(__CALLER__, "POST", path, module, method, opts)
  end

  @spec put(String.t(), Alias.t(), atom(), keyword()) :: :ok
  defmacro put(path, module, method, opts \\ []) do
    __match__(__CALLER__, "PUT", path, module, method, opts)
  end

  @spec patch(String.t(), Alias.t(), atom(), keyword()) :: :ok
  defmacro patch(path, module, method, opts \\ []) do
    __match__(__CALLER__, "PATCH", path, module, method, opts)
  end

  @spec connect(String.t(), Alias.t(), atom(), keyword()) :: :ok
  defmacro connect(path, module, method, opts \\ []) do
    __match__(__CALLER__, "CONNECT", path, module, method, opts)
  end

  @spec options(String.t(), Alias.t(), atom(), keyword()) :: :ok
  defmacro options(path, module, method, opts \\ []) do
    __match__(__CALLER__, "OPTIONS", path, module, method, opts)
  end

  @spec delete(String.t(), Alias.t(), atom(), keyword()) :: :ok
  defmacro delete(path, module, method, opts \\ []) do
    __match__(__CALLER__, "DELETE", path, module, method, opts)
  end

  @spec match(String.t() | Var.t(), String.t(), Alias.t(), atom(), keyword()) :: :ok
  defmacro match(verb, path, module, method, opts \\ []) do
    __match__(__CALLER__, verb, path, module, method, opts)
  end

  @spec __match__(
          Macro.Env.t(),
          String.t() | Var.t(),
          String.t(),
          Alias.t(),
          atom(),
          keyword()
        ) ::
          :ok
  defp __match__(env, verb, path, module, method, opts) do
    scope = Scope.get(env)
    Route.create(env, :match, scope, verb, path, module, method, opts)
  end

  @spec scope(String.t(), term()) :: :ok
  defmacro scope(path \\ "", do: block) do
    Scope.create(__CALLER__, path, block)
  end

  @spec forward(String.t(), Alias.t(), keyword()) :: :ok
  defmacro forward(path, module, opts \\ []) do
    scope = Scope.get(__CALLER__)
    Route.create(__CALLER__, :forward, scope, nil, path, module, nil, opts)
  end

  @spec pipeline(atom(), term()) :: :ok
  defmacro pipeline(name, do: block) do
    Pipeline.create(__CALLER__, name, block)
  end

  @spec plug(atom() | Alias.t(), keyword()) :: Honeybee.Plug.t()
  defmacro plug(plug, opts \\ []) do
    Plug.create(__CALLER__, plug, opts, true)
  end

  @spec pipe_through([atom]) :: :ok
  defmacro pipe_through(pipelines) when is_list(pipelines) do
    pipe_through = PipeThrough.create(__CALLER__, pipelines)
    Scope.pipe_through(__CALLER__, pipe_through)
  end

  @spec pipe_through(atom) :: :ok
  defmacro pipe_through(pipelines) do
    pipe_through = PipeThrough.create(__CALLER__, [pipelines])
    Scope.pipe_through(__CALLER__, pipe_through)
  end

  @spec __before_compile__(Macro.Env.t()) :: Macro.t()
  defmacro __before_compile__(env) do
    pipelines = Pipeline.get(env)
    routes = Route.get(env)

    compiled_pipelines =
      pipelines |> Enum.reverse() |> Enum.map(&Compiler.compile_pipeline(env, &1))

    compiled_routes = routes |> Enum.reverse() |> Enum.map(&Compiler.compile_route(env, &1))

    unmatched_capture =
      quote do
        def dispatch(_, pattern) do
          raise "No route matching " <> Enum.join(pattern, "/")
        end
      end

    compiled_pipelines ++ compiled_routes ++ [unmatched_capture]
  end
end
