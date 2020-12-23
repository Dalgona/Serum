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

  The argument must be a tuple with two elements, where the first one is an
  excetion struct provided in a `rescue` clause, and the second one is a
  stacktrace.

  To get a stacktrace, use `__STACKTRACE__/0` if inside a `rescue` block, or
  `Process.info(self(), :current_stacktrace)` if in anywhere else.

  If the stacktrace information is not available, put `nil` instead.
  """
  @impl true
  @spec message({Exception.t(), Exception.stacktrace()}) :: t()
  def message({%{__exception__: true} = exception, stacktrace}) do
    %__MODULE__{exception: exception, stacktrace: stacktrace}
  end
end
