defmodule Serum.Error.CycleMessage do
  @moduledoc """
  Defines a struct which contains information of cyclic dependency
  detected while expanding includes.
  """

  defstruct [:cycle]

  @type t :: %__MODULE__{cycle: [String.Chars.t()]}

  defimpl Serum.Error.Format do
    alias Serum.Error.CycleMessage

    def format_text(%CycleMessage{cycle: cycle}, _indent) do
      [
        "cycle detected while expanding includes:\n",
        make_graph(cycle),
        "  Cycles are not allowed when recursively including templates.\n",
        "  Please refactor your templates to break the cycle.\n",
        "  Alternatively, you can use the render/1,2 template helper.\n"
      ]
    end

    endl = [:reset, ?\n]
    top = ["    ", :red, "\u256d\u2500\u2500\u2500\u2500\u2500\u256e", endl]
    arrow = ["    ", :red, "\u2502     \u2193", endl]
    first_text = ["    ", :red, "\u2502    ", :yellow]
    rest_text = ["    ", :red, "\u2502    "]
    bottom1 = ["    ", :red, "\u2502     \u2502", endl]
    bottom2 = ["    ", :red, "\u2570\u2500\u2500\u2500\u2500\u2500\u256f", endl]

    @spec make_graph([String.Chars.t()]) :: IO.ANSI.ansidata()
    defp make_graph([first | rest]) do
      rest_graph =
        Enum.map(rest, fn name ->
          [
            unquote(arrow),
            unquote(rest_text),
            to_string(name),
            unquote(endl)
          ]
        end)

      [
        unquote(top),
        unquote(arrow),
        unquote(first_text),
        to_string(first),
        unquote(endl),
        rest_graph,
        unquote(bottom1),
        unquote(bottom2)
      ]
    end
  end
end
