defmodule Serum.Fragment do
  @moduledoc """
  Defines a struct representing a page fragment.

  ## Fields

  * `file`: Source path. This can be `nil` if created internally.
  * `output`: Destination path
  * `metadata`: A map holding extra information about the fragment
  * `data`: Contents of the page fragment
  """

  @type t :: %__MODULE__{
          file: binary() | nil,
          output: binary(),
          metadata: map(),
          data: binary()
        }

  defstruct [:file, :output, :metadata, :data]

  @doc "Creates a new `Fragment` struct."
  @spec new(binary() | nil, binary(), map(), binary()) :: t()
  def new(file, output, metadata, data) do
    images =
      data
      |> Floki.parse()
      |> Floki.find("img")
      |> Enum.map(fn {"img", attrs, _} -> Map.new(attrs)["src"] || [] end)
      |> List.flatten()

    %__MODULE__{
      file: file,
      output: output,
      metadata: Map.put(metadata, :images, images),
      data: data
    }
  end

  defprotocol Source do
    alias Serum.Project
    alias Serum.Result

    @spec to_fragment(term(), map(), Project.t()) :: Result.t(Fragment.t())
    def to_fragment(x, templates, proj)
  end
end
