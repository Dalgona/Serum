defmodule Serum.V2.Error.CycleMessage do
  @moduledoc """
  A struct containing information of cyclic dependency
  detected while expanding includes.
  """

  @behaviour Serum.V2.Error.Message

  defstruct [:cycle]

  @type t :: %__MODULE__{cycle: [String.Chars.t()]}

  @doc """
  Creates a `Serum.V2.Error.CycleMessage` struct.

  The argument must be a list with exactly one item, which is a list of any
  term that can be converted into a string via the `String.Chars` protocol.
  """
  @impl true
  @spec message([list()]) :: t()
  def message([items]) when is_list(items), do: %__MODULE__{cycle: items}
end
