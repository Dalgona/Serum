defmodule Serum.Error do
  @moduledoc "Defines a struct describing error information."

  alias Serum.Error.Format

  defstruct [:message, :exception, :stacktrace, :caused_by, :file, :line]

  @type t :: %__MODULE__{
          message: Format.t(),
          exception: Exception.t() | nil,
          stacktrace: stacktrace(),
          caused_by: [t()],
          file: Serum.File.t() | nil,
          line: integer()
        }

  @typep stacktrace :: [{atom(), atom(), integer(), keyword()}]
end
