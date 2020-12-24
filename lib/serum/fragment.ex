defmodule Serum.Fragment do
  @moduledoc false

  _moduledocp = """
  Defines functions internally used by Serum to create
  `Serum.V2.Fragment` structs.
  """

  require Serum.V2.Result, as: Result
  alias Serum.Plugin.Client, as: PluginClient
  alias Serum.V2
  alias Serum.V2.Fragment

  @doc "Creates a new `Fragment` struct."
  @spec new(V2.File.t(), binary(), map(), binary()) :: Result.t(Fragment.t())
  def new(source, dest, metadata, data) do
    Result.run do
      html_tree <- parse_html(data)
      html_tree <- preprocess(html_tree, metadata)

      Result.return(%Fragment{
        source: source,
        dest: dest,
        metadata: Map.put(metadata, :images, extract_images(html_tree)),
        data: Floki.raw_html(html_tree)
      })
    end
  end

  @spec parse_html(binary()) :: Result.t(Floki.html_tree())
  defp parse_html(html) do
    case Floki.parse_document(html) do
      {:ok, html_tree} -> Result.return(html_tree)
      {:error, message} -> Result.fail(message)
    end
  end

  @spec preprocess(Floki.html_tree(), map()) :: Result.t(Floki.html_tree())
  defp preprocess(html_tree, metadata) do
    html_tree
    |> Floki.traverse_and_update(%{}, &set_header_ids/2)
    |> elem(0)
    |> PluginClient.generating_fragment(metadata)
  end

  @spec set_header_ids(Floki.html_tag(), map()) :: {Floki.html_tag(), map()}
  defp set_header_ids(tree, state)

  defp set_header_ids({<<?h, ch::8>>, _, _} = tree, state) when ch in ?1..?6 do
    {tag_name, attrs, children} = tree

    case Enum.find(attrs, fn {k, _} -> k === "id" end) do
      {"id", id} ->
        {tree, increase_count(state, id)}

      nil ->
        id = generate_id(tree)

        new_tree =
          case state[id] do
            nil -> {tag_name, [{"id", id} | attrs], children}
            x -> {tag_name, [{"id", "#{id}-#{x + 1}"} | attrs], children}
          end

        {new_tree, increase_count(state, id)}
    end
  end

  defp set_header_ids(tree, state), do: {tree, state}

  @spec generate_id(Floki.html_tag()) :: binary()
  defp generate_id(tree) do
    [tree]
    |> Floki.text()
    |> String.downcase()
    |> String.replace(~r/\s/, "-")
  end

  @spec increase_count(map(), binary()) :: map()
  defp increase_count(map, id), do: Map.update(map, id, 1, &(&1 + 1))

  @spec extract_images(Floki.html_tree()) :: [binary()]
  defp extract_images(tree) do
    tree
    |> Floki.find("img")
    |> Enum.map(fn {"img", attrs, _} ->
      attrs |> Enum.find(fn {k, _} -> k === "src" end) |> elem(1)
    end)
    |> List.flatten()
  end
end
