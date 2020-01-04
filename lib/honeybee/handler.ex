defmodule Honeybee.Handler do
  @moduledoc """
  `Honeybee.Handler` provides a simple way to invoke methods from a pluggable module.

  When a handler is called, it expects to find the method to invoke in the `:action` option.
  For instance, a handler invoked using `plug Handler, action: :create`, will invoke the create method.

  The arguments passed to the action method is the conn, and the options for the invocation.
  The options for the invocation are expected to be in the `:opts` option.

  An example of a handler plug declaration looks like this
  ```
    plug Handler, action: :create, opts: []
  ```

  A handler can itself contain a plug pipeline, which is invoked prior to invocation of an action.
  These plugs behave very similarly to the plugs of the `Plug.Builder`, and support guards just like the `Honeybee` Router.
  However, in addition to the `method` variable in guards, it also provides an additional option, the `action` variable.

  Here is an exmaple of a Honeybee Handler implementation
  ```
  defmodule Example.Handler do
    use Honeybee.Handler

    plug Authorization when action in [:create]

    def create(conn, _opts) do
      body = conn.body_params

      user = Models.User.create(body)
      Plug.Conn.send_resp(conn, 200, user)
    end
  end
  ```
  """

  @doc false
  defmacro __using__(_opts \\ []) do
    quote do
      @behaviour Plug

      def init(opts), do: Keyword.split(opts, [:action])
      def call(%Elixir.Plug.Conn{} = conn, {[action: action], opts}) when is_atom(action) do
        honeybee_handler_call(conn, action, Keyword.get(opts, :opts, []))
      end
      def honeybee_action_call(conn, {action, opts}), do: apply(__MODULE__, action, [conn, opts])
      defoverridable init: 1, call: 2

      import Honeybee.Handler

      Module.register_attribute(__MODULE__, :plugs, accumulate: true)
      @before_compile Honeybee.Handler
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    opts = quote do: opts
    method = {:method, [generated: true], nil}
    action = {:action, [generated: true], nil}

    plugs = [
      {:honeybee_action_call, {:unquote, [], [{action, opts}]}, true}
      | Module.get_attribute(env.module, :plugs)
    ]
    {conn, body} = Plug.Builder.compile(env, plugs, [])

    quote generated: true do
      defp honeybee_handler_call(
        %Elixir.Plug.Conn{method: unquote(method)} = unquote(conn), unquote(action), unquote(opts)
      ), do: unquote(body)
    end
  end

  @doc """
  Declares a plug.

  The `plug/2` macro can be used to declare a plug in the plug pipeline.
  `Honeybee.Handler` supports plugs similar to the `Plug.Builder`, however there are a couple of caveats.

  `plug/2` has guard support, which allows us to guard for the `method` and the `action` of the plugged call.
  This allows you to write plugs which only apply to certain http-verbs of requests, and only certain actions.

  ```
  plug Authorization when method in ["POST", "PUT", "PATCH"] and action in [:create, :update]
  ```

  For more information on the plug pattern see `Plug`
  """
  defmacro plug(plug, opts \\ [])
  defmacro plug({:when, _, [plug, guards]}, opts), do: gen_plug(__CALLER__, plug, opts, guards)
  defmacro plug(plug, {:when, _, [opts, guards]}), do: gen_plug(__CALLER__, plug, opts, guards)
  defmacro plug(plug, opts), do: gen_plug(__CALLER__, plug, opts, true)

  defp gen_plug(env, plug, opts, guards) do
    plug = Macro.expand(plug, %{env | function: {:init, 1}})

    quote do: @plugs {unquote(plug), unquote(opts), unquote(Macro.escape(guards))}
  end
end
