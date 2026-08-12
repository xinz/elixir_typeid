defmodule Typeid.Macros do
  @moduledoc false

  defmacro defextension(module, do: body) do
    module = Macro.expand(module, __CALLER__)

    if Code.ensure_loaded?(module) do
      quote do
        unquote(body)
      end
    else
      quote do
        :ok
      end
    end
  end
end
