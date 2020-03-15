defmodule Serum.Post do
  @moduledoc false

  _moduledocp = """
  Defines functions internally used by Serum to create and manipulate
  `Serum.V2.Post` structs.
  """

  alias Serum.V2
  alias Serum.V2.Post
  alias Serum.V2.Tag

  @spec new(V2.File.t(), {map(), map()}, binary(), Project.t()) :: Post.t()
  def new(source, {header, extras}, data, proj) do
    filename = Path.relative_to(source.src, proj.src)
    tags = create_tags(header[:tags] || [], proj)
    date = header[:date]
    {type, original_ext} = get_type(filename)

    {url, dest} =
      with name <- String.replace_suffix(filename, original_ext, "html") do
        {Path.join(proj.base_url, name), Path.join(proj.dest, name)}
      end

    %Post{
      source: source,
      dest: dest,
      type: type,
      title: header[:title],
      date: date,
      tags: tags,
      url: url,
      data: data,
      template: header[:template],
      extras: extras
    }
  end

  @spec compact(Post.t()) :: map()
  def compact(%Post{} = post) do
    post
    |> Map.drop(~w(__struct__ source dest type data)a)
    |> Map.put(:type, :post)
  end

  @spec create_tags([binary()], Project.t()) :: [Tag.t()]
  defp create_tags(tag_names, proj) do
    tag_names
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.map(
      &%Tag{
        name: &1,
        path: Path.join([proj.base_url, "tags", &1])
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
