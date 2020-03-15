defmodule Serum.Template do
  @moduledoc "Defines a struct which stores a template and its information."

  alias Serum.V2

  defstruct name: "",
            type: :template,
            file: %V2.File{},
            ast: nil,
            include_resolved?: false

  @type t() :: %__MODULE__{
          name: binary(),
          type: type(),
          file: V2.File.t(),
          ast: Macro.t(),
          include_resolved?: boolean()
        }

  @type collection() :: %{optional(binary()) => t()}
  @type type() :: :template | :include

  @spec new(Macro.t(), binary(), type(), V2.File.t()) :: t()
  def new(ast, name, type, file) do
    %__MODULE__{
      name: name,
      type: type,
      file: file,
      ast: ast,
      include_resolved?: false
    }
  end
end
