defmodule Serum.Fragment do
  @type t :: %__MODULE__{
          file: binary() | nil,
          output: binary(),
          title: binary(),
          type: atom(),
          data: binary()
        }

  defstruct [:file, :output, :title, :type, :data]

  @spec new(atom(), struct(), binary()) :: t()
  def new(type, struct, data) do
    %__MODULE__{
      file: Map.get(struct, :file),
      output: struct.output,
      title: struct.title,
      type: type,
      data: data
    }
  end
end
