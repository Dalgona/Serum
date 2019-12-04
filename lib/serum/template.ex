defmodule Serum.Template do
  @moduledoc "Defines a struct which stores a template and its information."

  defstruct name: "",
            type: :template,
            file: %Serum.File{},
            ast: nil,
            include_resolved?: false

  @type t() :: %__MODULE__{
          name: binary(),
          type: type(),
          file: Serum.File.t(),
          ast: Macro.t(),
          include_resolved?: boolean()
        }

  @type collection() :: %{optional(binary()) => t()}
  @type type() :: :template | :include

  @spec new(Macro.t(), binary(), type(), Serum.File.t()) :: t()
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
