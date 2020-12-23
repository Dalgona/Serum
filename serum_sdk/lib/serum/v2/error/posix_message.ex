defmodule Serum.V2.Error.POSIXMessage do
  @moduledoc "A struct containing POSIX error messages in atom."

  @behaviour Serum.V2.Error.Message

  defstruct [:reason]

  @type t :: %__MODULE__{reason: atom()}

  @doc """
  Creates a `Serum.V2.Error.POSIXMessage` struct.

  The argument must be an atom describing a POSIX error. See `t::file.posix/0`
  for more information about valid atoms.
  """
  @impl true
  @spec message(atom()) :: t()
  def message(reason) when is_atom(reason), do: %__MODULE__{reason: reason}
end
