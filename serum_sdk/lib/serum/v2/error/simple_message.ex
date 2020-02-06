defmodule Serum.V2.Error.SimpleMessage do
  @moduledoc "A struct containing simple text-based error message."

  @behaviour Serum.V2.Error.Message

  defstruct [:text]

  @type t :: %__MODULE__{text: binary()}

  @doc """
  Creates a `Serum.V2.Error.SimpleMessage` struct.

  The argument must be a list with exactly one item, which is the message text.
  """
  @impl true
  @spec message([binary()]) :: t()
  def message([text]) when is_binary(text), do: %__MODULE__{text: text}
end
