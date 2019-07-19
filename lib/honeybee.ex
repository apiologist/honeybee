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
  alias Honeybee.Pipe
  alias Honeybee.Using
  alias Honeybee.Compiler
  alias Plug

  defmacro __using__(_ \\ []) do
    env = __CALLER__
    Scope.init(env)
    Route.init(env)
    Pipe.init(env)

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

  @spec pipe(atom(), term()) :: :ok
  defmacro pipe(name, do: block) do
    Pipe.create(__CALLER__, name, block)
  end

  @spec plug(atom() | Alias.t(), keyword()) :: Honeybee.Plug.t()
  defmacro plug(plug, opts \\ []) do
    Plug.create(__CALLER__, plug, opts, true)
  end

  @spec using([atom]) :: :ok
  defmacro using(pipes) when is_list(pipes) do
    using = Using.create(__CALLER__, pipes)
    Scope.using(__CALLER__, using)
  end

  @spec using(atom) :: :ok
  defmacro using(pipes) do
    using = Using.create(__CALLER__, [pipes])
    Scope.using(__CALLER__, using)
  end

  @spec __before_compile__(Macro.Env.t()) :: Macro.t()
  defmacro __before_compile__(env) do
    pipes = Pipe.get(env)
    routes = Route.get(env)

    compiled_pipes =
      pipes |> Enum.reverse() |> Enum.map(&Compiler.compile_pipe(env, &1))

    compiled_routes = routes |> Enum.reverse() |> Enum.map(&Compiler.compile_route(env, &1))

    unmatched_capture =
      quote do
        def dispatch(%Elixir.Plug.Conn{method: method}, pattern) do
          raise "No matching route for request: " <> method <> " /" <> Enum.join(pattern, "/")
        end
      end

    compiled_pipes ++ compiled_routes ++ [unmatched_capture]
  end
end
