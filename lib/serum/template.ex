defmodule Serum.Template do
  @moduledoc "Defines a struct which stores a template and its information."

  @type t() :: %__MODULE__{
          type: type(),
          file: binary(),
          ast: Macro.t(),
          include_resolved?: boolean()
        }

  @type collection() :: %{optional(binary()) => t()}
  @type type() :: :template | :include

  defstruct type: :template, file: nil, ast: nil, include_resolved?: false

  @spec new(Macro.t(), type(), binary()) :: t()
  def new(ast, type, path) do
    %__MODULE__{
      type: type,
      file: path,
      ast: ast,
      include_resolved?: false
    }
  end
end
