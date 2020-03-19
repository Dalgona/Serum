defmodule Serum.Template do
  @moduledoc false

  _moduledocp = """
  Defines functions internally used by Serum to create
  `Serum.V2.Template` structs.
  """

  alias Serum.V2
  alias Serum.V2.Template

  @spec new(Macro.t(), binary(), Template.type(), V2.File.t()) :: Template.t()
  def new(ast, name, type, source) do
    %Template{
      source: source,
      name: name,
      type: type,
      ast: ast,
      include_resolved?: false
    }
  end
end
