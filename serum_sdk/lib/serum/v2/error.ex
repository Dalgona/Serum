defmodule Serum.V2.Error do
  @moduledoc """
  A struct containing error information.

  ## Fields

  - `message` - the error message.
  - `caused_by` - a list of `Serum.V2.Error` structs describing causes of this
    error. This list can be empty.
  - `file` - a `Serum.V2.File` struct holding information about the file which
    caused this error, or `nil`.
  - `line` - the line number in `file`, or `nil`. This value must be ignored if
    `file` is `nil`.
  """

  alias Serum.V2
  alias Serum.V2.Error.Message

  defstruct [:message, :caused_by, :file, :line]

  @type t :: %__MODULE__{
          message: Message.t(),
          caused_by: [t()],
          file: V2.File.t() | nil,
          line: integer() | nil
        }

  @doc "Performs pre-order traversal over the given error."
  @spec prewalk(t(), (t() -> t())) :: t()
  def prewalk(error, fun) do
    %__MODULE__{caused_by: errors} = error2 = fun.(error)

    %__MODULE__{error2 | caused_by: Enum.map(errors, &prewalk(&1, fun))}
  end
end
