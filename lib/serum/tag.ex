defmodule Serum.Tag do
  @moduledoc "This module defines Tag struct."

  @type t :: %__MODULE__{
          name: binary(),
          list_url: binary()
        }

  defstruct [:name, :list_url]

  @spec new(binary(), map()) :: t()
  def new(name, proj) do
    %__MODULE__{
      name: name,
      list_url: Path.join([proj.base_url, "tags", name])
    }
  end

  @spec batch_create([binary()], map()) :: [t()]
  def batch_create(names, proj) do
    names |> Enum.uniq() |> Enum.sort() |> Enum.map(&new(&1, proj))
  end
end
