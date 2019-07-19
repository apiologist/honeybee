defmodule Honeybee.Compiler do
  defmodule CompileError do
    use Honeybee.Utils.Error
  end

  @moduledoc false
  def compile_pipe(env, %Honeybee.Pipe{name: name, plugs: plugs, line: line}) do
    plug_pipe =
      plugs
      |> Enum.reverse()
      |> Enum.map(&Honeybee.Plug.as_plug/1)
      |> Enum.map(fn
        {fun, opts, guards} ->
          {
            Macro.expand(fun, env),
            Macro.prewalk(opts, &Macro.expand(&1, env)),
            guards
          }
      end)

    {conn, ast} = Plug.Builder.compile(env, plug_pipe, [])

    compiled_pipe =
      quote do
        def using(unquote(conn), unquote(name)) do
          unquote(ast)
        end
      end

    set_line(compiled_pipe, line)
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

    method = case route.type do
      :forward -> :call
      :match -> route.method
    end

    %_{ module: module } = route

    err_msg = "Expected #{inspect(route.module)} to export function #{method}/2"

    case env.module do
      ^module ->
        if !Module.defines?(module, {method, 2}) do
          raise CompileError, env: env, line: route.line, message: err_msg
        end
      _ ->
        if !function_exported?(module, method, 2) do
          raise CompileError, env: env, line: route.line, message: err_msg
        end
    end

    uri =
      case type do
        :forward -> path(scope) <> path <> "/:*forward_route"
        :match -> path(scope) <> path
      end

    verb =
      case type do
        :forward -> quote(do: _)
        _ -> verb
      end

    {pattern, params} = Honeybee.Utils.Path.compile(uri)

    compiled_params = compile_params(params)
    compiled_pipes = compile_pipes(scope)
    compiled_call = compile_call(route)

    components = compiled_pipes ++ [compiled_call]
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

  defp compile_pipes(scope) do
    scope
    |> Enum.reverse()
    |> Enum.flat_map(& &1.using)
    |> Enum.flat_map(& &1.pipes)
    |> Enum.map(&quote(do: using(unquote(conn()), unquote(&1))))
  end

  defp compile_call(%Honeybee.Route{
         type: :match,
         module: module,
         method: method,
         opts: opts
       }) do
    err_msg =
      "Expected " <>
        inspect(module) <> "." <> Atom.to_string(method) <> "/2 to return a connection, got: "

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
