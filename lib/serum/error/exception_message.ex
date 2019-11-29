defmodule Serum.Error.ExceptionMessage do
  @moduledoc """
  Defines a struct which contains exception and stacktrace (if any) information.
  """

  defstruct [:exception, :stacktrace]

  @type t :: %__MODULE__{
          exception: Exception.t(),
          stacktrace: Exception.stacktrace()
        }

  defimpl Serum.Error.Format do
    alias Serum.Error.ExceptionMessage

    def format_text(%ExceptionMessage{} = msg, _indent) do
      Exception.format(:error, msg.exception, msg.stacktrace)
    end
  end
end
