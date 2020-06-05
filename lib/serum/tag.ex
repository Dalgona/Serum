defmodule Serum.Tag do
  @moduledoc "This module defines Tag struct."

  alias Serum.Project

  @type t :: %__MODULE__{
          name: binary(),
          list_url: binary()
        }

  defstruct [:name, :list_url]

  @spec new(binary(), Project.t()) :: t()
  def new(name, %Project{} = proj) do
    %__MODULE__{
      name: name,
      list_url: Path.join([proj.base_url, proj.tags_path, name])
    }
  end

  @spec batch_create([binary()], Project.t()) :: [t()]
  def batch_create(names, %Project{} = proj) do
    names |> Enum.uniq() |> Enum.sort() |> Enum.map(&new(&1, proj))
  end
end
