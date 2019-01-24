defmodule Honeybee.Compiler do
  @moduledoc false
  def compile_pipeline(env, %Honeybee.Pipeline{name: name, plugs: plugs, line: line}) do
    plug_pipeline =
      plugs
      |> Enum.reverse()
      |> Enum.map(&Honeybee.Plug.as_plug/1)
      |> Macro.prewalk(&Macro.expand_once(&1, env))

    {conn, ast} = Plug.Builder.compile(env, plug_pipeline, [])

    compiled_pipeline =
      quote do
        def pipe_through(unquote(conn), unquote(name)) do
          unquote(ast)
        end
      end

    set_line(compiled_pipeline, line)
  end

  def compile_route(
        env,
        %Honeybee.Route{
          type: type,
          scope: scope,
          verb: verb,
          path: path
        } = route
      ) do
    route = %Honeybee.Route{
      route
      | module: Macro.expand(route.module, env),
        opts: Macro.expand(route.opts, env)
    }

    uri =
      case type do
        :forward -> path(scope) <> path <> ":*forward_route"
        :match -> path(scope) <> path
      end

    verb =
      case type do
        :forward -> quote(do: _)
        _ -> verb
      end

    {pattern, params} = Honeybee.Utils.Path.compile(uri)

    compiled_params = compile_params(params)
    compiled_pipe_through = compile_pipe_through(scope)
    compiled_call = compile_call(route)

    components = compiled_pipe_through ++ [compiled_call]
    compiled_block = concat_compiled(components)

    compiled_route =
      quote do
        def dispatch(
              %Plug.Conn{method: unquote(verb)} = unquote(conn()),
              unquote(pattern)
            ) do
          unquote(compiled_params)
          unquote(compiled_block)
        end
      end

    set_line(compiled_route, route.line)
  end

  defp path(scope) do
    scope
    |> Enum.reverse()
    |> Enum.map(& &1.path)
    |> Enum.join()
  end

  defp conn() do
    quote(do: conn)
  end

  defp compile_params(params) do
    quote(do: unquote(conn()) = %Plug.Conn{unquote(conn()) | path_params: unquote(params)})
  end

  defp compile_pipe_through(scope) do
    scope
    |> Enum.reverse()
    |> Enum.flat_map(& &1.pipe_through)
    |> Enum.flat_map(& &1.pipelines)
    |> Enum.map(&quote(do: pipe_through(unquote(conn()), unquote(&1))))
  end

  defp compile_call(%Honeybee.Route{
         type: :match,
         module: module,
         method: method,
         opts: opts
       }) do
    err_msg =
      "Expected " <>
        inspect(module) <> "." <> inspect(method) <> "/2 to return a connection, got: "

    quote do
      case unquote(module).unquote(method)(unquote(conn()), unquote(opts)) do
        %Plug.Conn{} = conn -> conn
        other -> raise unquote(err_msg) <> "#{inspect(other)}"
      end
    end
  end

  defp compile_call(%Honeybee.Route{type: :forward, module: module, opts: opts}) do
    initialized_opts = module.init(opts)

    quote do
      unquote(module).call(unquote(conn()), [
        {:match_route, unquote(conn()).path_params["forward_route"]}
        | unquote(initialized_opts)
      ])
    end
  end

  defp concat_compiled(quoted) do
    Enum.reduce(
      quoted,
      &quote do
        case unquote(&2) do
          %Plug.Conn{halted: true} = conn ->
            conn

          %Plug.Conn{} = unquote(conn()) ->
            unquote(&1)
        end
      end
    )
  end

  defp set_line(quoted, line) do
    Macro.prewalk(quoted, fn
      {func, meta, args} -> {func, [{:line, line}, {:generated, true} | meta], args}
      other -> other
    end)
  end
end
