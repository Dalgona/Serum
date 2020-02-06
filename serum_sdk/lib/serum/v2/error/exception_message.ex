defmodule Serum.V2.Error.ExceptionMessage do
  @moduledoc """
  A struct containing exception and stacktrace information (if any).
  """

  @behaviour Serum.V2.Error.Message

  defstruct [:exception, :stacktrace]

  @type t :: %__MODULE__{
          exception: Exception.t(),
          stacktrace: Exception.stacktrace()
        }

  @doc """
  Creates a `Serum.V2.Error.ExceptionMessage` struct.

  The argument must be a list with exactly two items, where the first one is an
  exception information retrieved in a `rescue` block, and the second one is
  the stacktrace information.

  To get a stacktrace, use `__STACKTRACE__/0` if inside a `rescue` block, or
  `Process.info(self(), :current_stacktrace)` if in anywhere else.

  The second list item cannot be omitted. If the stacktrace information is not
  available, put `nil` instead.
  """
  @impl true
  @spec message([Exception.t() | Exception.stacktrace()]) :: t()
  def message([exception, stacktrace]) do
    %__MODULE__{exception: exception, stacktrace: stacktrace}
  end
end
