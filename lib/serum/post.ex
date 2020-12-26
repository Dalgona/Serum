defmodule Serum.Post do
  @moduledoc false

  _moduledocp = """
  Defines functions internally used by Serum to create and manipulate
  `Serum.V2.Post` structs.
  """

  alias Serum.HeaderParser.ParseResult
  alias Serum.V2
  alias Serum.V2.BuildContext
  alias Serum.V2.Post
  alias Serum.V2.Tag

  @spec new(V2.File.t(), ParseResult.t(), BuildContext.t()) :: Post.t()
  def new(source, %ParseResult{} = header, %BuildContext{} = context) do
    base_url = context.project.base_url.path
    filename = Path.relative_to(source.src, context.source_dir)
    {type, original_ext} = get_type(filename)

    {url, dest} =
      with name <- String.replace_suffix(filename, original_ext, "html") do
        {Path.join(base_url, name), Path.join(context.dest_dir, name)}
      end

    %Post{
      source: source,
      dest: dest,
      type: type,
      title: header.data[:title],
      date: header.data[:date] || Timex.to_datetime(Timex.zero(), :local),
      tags: create_tags(header.data[:tags] || [], base_url),
      url: url,
      data: header.rest,
      template: header.data[:template],
      extras: Map.put(header.extras, "__serum__next_line__", header.next_line)
    }
  end

  @spec create_tags([binary()], binary()) :: [Tag.t()]
  defp create_tags(tag_names, base_url) do
    tag_names
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.map(
      &%Tag{
        name: &1,
        url: Path.join([base_url, "tags", &1])
      }
    )
  end

  @spec get_type(binary()) :: {binary(), binary()}
  defp get_type(filename) do
    filename
    |> Path.basename()
    |> String.split(".", parts: 2)
    |> Enum.reverse()
    |> hd()
    |> case do
      "html.eex" -> {"html", "html.eex"}
      type -> {type, type}
    end
  end
end
