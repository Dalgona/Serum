defmodule Serum.Error.SimpleMessage do
  @moduledoc "Defines a struct which contains simple text-based error message."

  defstruct [:text]

  @type t :: %__MODULE__{text: binary()}

  defimpl Serum.Error.Format do
    alias Serum.Error.SimpleMessage

    def format_text(%SimpleMessage{text: text}, _indent), do: text
  end
end
