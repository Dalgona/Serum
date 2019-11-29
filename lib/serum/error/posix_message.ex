defmodule Serum.Error.POSIXMessage do
  @moduledoc "Defines a struct which contains POSIX error messages in atom."

  defstruct [:reason]

  @type t :: %__MODULE__{reason: atom()}

  defimpl Serum.Error.Format do
    alias Serum.Error.POSIXMessage

    def format_text(%POSIXMessage{reason: reason}, _indent) do
      :file.format_error(reason)
    end
  end
end
