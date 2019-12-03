defmodule Serum.Error.SimpleMessage do
  @moduledoc "Defines a struct which contains simple text-based error message."

  @behaviour Serum.Error.Message

  defstruct [:text]

  @type t :: %__MODULE__{text: binary()}

  def message([text]) when is_binary(text), do: %__MODULE__{text: text}

  defimpl Serum.Error.Format do
    alias Serum.Error.SimpleMessage

    def format_text(%SimpleMessage{text: text}, _indent), do: text
  end
end
