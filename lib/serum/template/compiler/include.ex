defmodule Serum.Template.Compiler.Include do
  @moduledoc false

  _moduledocp = "Provides functions for expanding includes in templates."

  alias Serum.Template.Storage, as: TS

  @spec expand(Macro.t()) :: {:ok, Macro.t()} | {:ct_error, binary(), binary()}
  def expand(ast) do
    {new_ast, _} = Macro.prewalk(ast, [], &do_expand_includes(&1, &2))

    {:ok, new_ast}
  rescue
    e in ArgumentError ->
      {:ct_error, "include not found: \"#{e.message}\"", 0}

    e in RuntimeError ->
      {:ct_error, e.message, 0}
  end

  @spec do_expand_includes(Macro.t(), [binary()]) :: {Macro.t(), [binary()]}
  defp do_expand_includes(ast, stack)

  defp do_expand_includes({:include, _, [arg]}, stack) do
    case TS.get(arg, :include) do
      nil ->
        raise ArgumentError, arg

      include ->
        check_cycle!(arg, stack)

        {quote(do: (fn -> unquote(include.ast) end).()), [arg | stack]}
    end
  end

  defp do_expand_includes(anything_else, stack), do: {anything_else, stack}

  top = "    \x1b[31m\u256d\u2500\u2500\u2500\u2500\u2500\u256e\x1b[m\n"
  arrow = "    \x1b[31m\u2502     \u2193\x1b[m\n"
  first_text = "    \x1b[31m\u2502    \x1b[33m"
  rest_text = "    \x1b[31m\u2502    "
  bottom1 = "    \x1b[31m\u2502     \u2502\x1b[m\n"
  bottom2 = "    \x1b[31m\u2570\u2500\u2500\u2500\u2500\u2500\u256f\x1b[m\n"

  @spec check_cycle!(binary(), [binary()]) :: nil | no_return()
  defp check_cycle!(name, stack) do
    if name in stack do
      graph =
        stack
        |> Enum.reverse()
        |> Enum.drop_while(&(&1 != name))
        |> make_graph()

      message = [
        "cycle detected while expanding includes:\n",
        graph,
        "  Recursively including templates is not supported by Serum.\n",
        "  Please refactor your templates to break the cycle."
      ]

      raise IO.iodata_to_binary(message)
    end
  end

  @spec make_graph([binary()]) :: iodata()
  defp make_graph([first | rest]) do
    rest_graph =
      Enum.map(rest, fn name ->
        [
          unquote(arrow),
          unquote(rest_text),
          name,
          "\x1b[m\n"
        ]
      end)

    [
      unquote(top),
      unquote(arrow),
      unquote(first_text),
      first,
      "\x1b[m\n",
      rest_graph,
      unquote(bottom1),
      unquote(bottom2)
    ]
  end
end
