defmodule Generator do 
  def gen_router(module_name, :honeybee, routes) do
    Module.create(module_name, quote do
      use RouterGenerators.Honeybee, routes: unquote(routes)
    end, __ENV__)
    nil
  end
  def gen_router(module_name, :phoenix, routes) do
    Module.create(module_name, quote do
      use RouterGenerators.Phoenix, routes: unquote(routes)
    end, __ENV__)
    nil
  end
  def gen_router(module_name, :plug, routes) do
    Module.create(module_name, quote do
      use RouterGenerators.Plug, routes: unquote(routes)
    end, __ENV__)
    nil
  end
end
