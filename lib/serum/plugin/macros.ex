defmodule Serum.Plugin.Macros do
  @moduledoc false

  _moduledocp = "Provides macros for defining the `Serum.Plugin` module."

  defmacro defcallback({:::, _, [{name, meta, args} = call, return]}) do
    arg_expr = quote(do: args :: term())

    quote do
      @callback unquote(call) :: unquote(return)
      @callback unquote({name, meta, args ++ [arg_expr]}) :: unquote(return)
    end
  end
end
