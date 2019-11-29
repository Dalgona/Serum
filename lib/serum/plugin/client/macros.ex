defmodule Serum.Plugin.Client.Macros do
  @moduledoc false

  defmacro interface(type, typespec) when type in ~w(action function)a do
    {:"::", _, [{name, _, args}, _]} = typespec
    arg_vars = Enum.map(args, fn {:"::", _, [var, _]} -> var end)

    quote do
      @doc false
      @spec unquote(typespec)
      def unquote(name)(unquote_splicing(arg_vars)) do
        unquote(:"call_#{type}")(unquote(name), unquote(arg_vars))
      end
    end
  end
end
