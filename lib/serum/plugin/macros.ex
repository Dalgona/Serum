defmodule Serum.Plugin.Macros do
  @moduledoc false

  _moduledocp = "Provides macros for defining the `Serum.Plugin` module."

  @spec defcallback(Macro.t()) :: Macro.t()
  defmacro defcallback({:"::", _, [{name, meta, args} = call, return]}) do
    arg_expr = quote(do: args :: term())

    quote do
      @callback unquote(call) :: unquote(return)
      @callback unquote({name, meta, args ++ [arg_expr]}) :: unquote(return)
    end
  end

  @spec action(Macro.t()) :: Macro.t()
  defmacro action(spec) do
    client(:action, __CALLER__.module, spec)
  end

  @spec function(Macro.t()) :: Macro.t()
  defmacro function(spec) do
    client(:function, __CALLER__.module, spec)
  end

  @spec client(atom(), module(), Macro.t()) :: Macro.t()
  defp client(type, calling_module, {:"::", _, [{name, meta, args} = call, return]}) do
    arg_vars =
      args
      |> Enum.map(fn {:"::", _, [{var_name, _, _}, _type]} -> var_name end)
      |> Enum.map(&Macro.var(&1, calling_module))

    def_call_expr = {name, meta, arg_vars}
    def_body_expr = {:"call_#{type}", [], [name, arg_vars]}

    quote do
      @spec unquote(call) :: unquote(return)
      def unquote(def_call_expr), do: unquote(def_body_expr)
    end
  end
end
