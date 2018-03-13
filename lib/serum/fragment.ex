defmodule Serum.Fragment do
  @type t :: %__MODULE__{
          file: binary() | nil,
          output: binary(),
          metadata: map(),
          data: binary()
        }

  defstruct [:file, :output, :metadata, :data]

  @spec new(binary() | nil, binary(), map(), binary()) :: t()
  def new(file, output, metadata, data) do
    %__MODULE__{
      file: file,
      output: output,
      metadata: metadata,
      data: data
    }
  end
end
