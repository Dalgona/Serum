defmodule Serum.Template do
  @moduledoc "Defines a struct which stores a template and its information."

  @type t() :: %__MODULE__{
          name: binary(),
          type: type(),
          file: binary(),
          ast: Macro.t(),
          include_resolved?: boolean()
        }

  @type collection() :: %{optional(binary()) => t()}
  @type type() :: :template | :include

  defstruct name: "",
            type: :template,
            file: nil,
            ast: nil,
            include_resolved?: false

  @spec new(Macro.t(), binary(), type(), binary()) :: t()
  def new(ast, name, type, path) do
    %__MODULE__{
      name: name,
      type: type,
      file: path,
      ast: ast,
      include_resolved?: false
    }
  end
end
