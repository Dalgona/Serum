defmodule Serum.V2.Template do
  @moduledoc """
  A struct containing information about a template or include.

  ## Fields

  - `source` - a `Serum.V2.File` struct holding the source file information.
  - `name` - name of the template.
  - `type` - type of the template. Valid values are `:template` and `:include`.
  - `ast` - an Elixir AST of the template, compiled from the source file.
  - `include_resolved?` - indicates whether calls to `include/1` template helper
    macro have been fully resolved and expanded into corresponding includes.
  """

  alias Serum.V2

  @type t :: %__MODULE__{
          source: V2.File.t(),
          name: binary(),
          type: type(),
          ast: Macro.t(),
          include_resolved?: boolean()
        }

  @type collection :: %{optional(binary()) => t()}
  @type type :: :template | :include

  defstruct ~w(source name type ast include_resolved?)a
end
