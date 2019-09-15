defmodule Serum.Template do
  @moduledoc "Defines a struct which stores a template and its information."

  @type t() :: %__MODULE__{
          type: type(),
          file: binary(),
          ast: Macro.t()
        }

  @type collection() :: %{optional(binary()) => t()}
  @type type() :: :template | :include

  defstruct type: :template, file: nil, ast: nil

  @spec new(Macro.t(), type(), binary()) :: t()
  def new(ast, type, path) do
    %__MODULE__{
      type: type,
      file: path,
      ast: ast
    }
  end
end
