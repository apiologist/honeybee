defmodule Honeybee.Utils.Error do
  @moduledoc false
  defmacro __using__(_ \\ []) do
    quote do
      defexception [:message, :env, :file, :line]

      @impl true
      def exception(opts) do
        msg = Keyword.fetch!(opts, :message)
        env = Keyword.fetch!(opts, :env)
        line = Keyword.get(opts, :line, env.line)
        file = Keyword.get(opts, :file, env.file)

        %__MODULE__{message: msg, env: env, file: file, line: line}
      end

      @impl true
      def blame(err, stacktrace) do
        case err.env do
          nil ->
            {err, stacktrace}

          _env ->
            env = %Macro.Env{err.env | line: err.line, file: err.file}
            {err, Macro.Env.stacktrace(env)}
        end
      end
    end
  end
end
