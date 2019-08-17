defmodule RouterGenerators do
  defmodule Honeybee do
    defmacro __using__(opts \\ []) do
      routes = Macro.prewalk(Keyword.fetch!(opts, :routes), &Macro.expand(&1, __CALLER__))

      method_mapper = %{
        get: "GET",
        post: "POST",
        put: "PUT",
        delete: "DELETE",
        all: quote do _ end
      }

      route_statements = for %{ path: path, method: method, handler: handler } <- routes do
        method = Map.fetch!(method_mapper, method)
        quote do
          match(unquote(method), unquote(path)) do
            plug unquote(handler), action: :benchmark
          end
        end
      end

      router_setup = quote do
        use Elixir.Honeybee
      end

      compile_time_callbacks = quote do
        @before_compile RouterGenerators
        @after_compile RouterGenerators
      end

      [compile_time_callbacks, router_setup] ++ route_statements
    end
  end

  defmodule Phoenix do
    defmacro __using__(opts \\ []) do
      routes = Macro.prewalk(Keyword.fetch!(opts, :routes), &Macro.expand(&1, __CALLER__))

      method_mapper = %{
        get: :get,
        post: :post,
        put: :put,
        delete: :delete,
        all: :*
      }

      route_statements = for %{ path: path, method: method, handler: handler } <- routes do
        method = Map.fetch!(method_mapper, method)
        quote do
          match(unquote(method), unquote(path), unquote(handler), :benchmark)
        end
      end

      router_setup = quote do
        use Elixir.Phoenix.Router
      end

      compile_time_callbacks = quote do
        @before_compile RouterGenerators
        @after_compile RouterGenerators
      end

      [compile_time_callbacks, router_setup] ++ route_statements
    end
  end


  defmodule Plug do
    defmacro __using__(opts \\ []) do
      routes = Macro.prewalk(Keyword.fetch!(opts, :routes), &Macro.expand(&1, __CALLER__))

      method_mapper = %{
        get: :get,
        post: :post,
        put: :put,
        delete: :delete,
        all: [:get, :post, :put, :delete]
      }


      route_statements = for %{ path: path, method: method, handler: handler } <- routes do
        method = Map.fetch!(method_mapper, method)
        quote do
          match unquote(path), via: unquote(method), do: unquote(handler).benchmark(var!(conn))
        end
      end

      router_setup = quote do
        use Elixir.Plug.Router
      
        plug(:match)
        plug(:dispatch)
      end

      compile_time_callbacks = quote do
        @before_compile RouterGenerators
        @after_compile RouterGenerators
      end

      [compile_time_callbacks, router_setup] ++ route_statements
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def compile_start, do: unquote(DateTime.to_unix DateTime.utc_now, :millisecond)
    end
  end

  defmacro __after_compile__(env, _bytecode) do
    compile_end = DateTime.to_unix DateTime.utc_now, :millisecond
    compile_start = apply(env.module, :compile_start, [])

    IO.puts("Compiled in " <> to_string(compile_end - compile_start) <> "ms")
  end
end
