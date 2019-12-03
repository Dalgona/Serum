defmodule Serum.Error.POSIXMessage do
  @moduledoc "Defines a struct which contains POSIX error messages in atom."

  @behaviour Serum.Error.Message

  defstruct [:reason]

  @type t :: %__MODULE__{reason: atom()}

  def message([reason]) when is_atom(reason), do: %__MODULE__{reason: reason}

  defimpl Serum.Error.Format do
    alias Serum.Error.POSIXMessage

    def format_text(%POSIXMessage{reason: reason}, _indent) do
      :file.format_error(reason)
    end
  end
end
