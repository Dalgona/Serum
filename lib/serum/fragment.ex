defmodule Serum.Fragment do
  @type t :: %__MODULE__{
    file: binary() | nil,
    output: binary(),
    title: binary(),
    type: atom(),
    data: binary()
  }

  defstruct [:file, :output, :title, :type, :data]
end
