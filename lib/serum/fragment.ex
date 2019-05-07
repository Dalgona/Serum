defmodule Serum.Fragment do
  @moduledoc """
  Defines a struct representing a page fragment.

  ## Fields

  * `file`: Source path. This can be `nil` if created internally.
  * `output`: Destination path
  * `metadata`: A map holding extra information about the fragment
  * `data`: Contents of the page fragment
  """

  alias Serum.Plugin

  @type t :: %__MODULE__{
          file: binary() | nil,
          output: binary(),
          metadata: map(),
          data: binary()
        }

  defstruct [:file, :output, :metadata, :data]

  @doc "Creates a new `Fragment` struct."
  @spec new(binary() | nil, binary(), map(), binary()) :: Result.t(t())
  def new(file, output, metadata, data) do
    case Plugin.rendering_fragment(Floki.parse(data), metadata) do
      {:ok, html_tree} ->
        images =
          html_tree
          |> Floki.find("img")
          |> Enum.map(fn {"img", attrs, _} -> Map.new(attrs)["src"] || [] end)
          |> List.flatten()

        fragment = %__MODULE__{
          file: file,
          output: output,
          metadata: Map.put(metadata, :images, images),
          data: Floki.raw_html(html_tree)
        }

        {:ok, fragment}

      {:error, _} = error ->
        error
    end
  end

  defprotocol Source do
    alias Serum.Result

    @spec to_fragment(term(), map()) :: Result.t(Fragment.t())
    def to_fragment(x, templates)
  end
end
