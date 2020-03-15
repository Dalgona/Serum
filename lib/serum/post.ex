defmodule Serum.Post do
  @moduledoc """
  Defines a struct representing a blog post page.

  ## Fields

  * `file`: Source file
  * `type`: Type of source file
  * `title`: Post title
  * `date`: A `DateTime` struct representing the post date
  * `tags`: A list of tags
  * `url`: Absolute URL of the blog post in the website
  * `data`: Source or processed contents data
  * `output`: Destination path
  * `extras`: A map for storing arbitrary key-value data
  * `template`: Name of custom template or `nil`
  """

  alias Serum.Project
  alias Serum.V2.Tag

  @type t :: %__MODULE__{
          file: Serum.File.t(),
          type: binary(),
          title: binary(),
          date: DateTime.t(),
          tags: [Tag.t()],
          url: binary(),
          data: binary(),
          output: binary(),
          extras: map(),
          template: binary() | nil
        }

  defstruct [
    :file,
    :type,
    :title,
    :date,
    :tags,
    :url,
    :data,
    :output,
    :extras,
    :template
  ]

  @spec new(Serum.File.t(), {map(), map()}, binary(), Project.t()) :: t()
  def new(file, {header, extras}, data, proj) do
    filename = Path.relative_to(file.src, proj.src)
    tags = create_tags(header[:tags] || [], proj)
    datetime = header[:date]
    {type, original_ext} = get_type(filename)

    {url, output} =
      with name <- String.replace_suffix(filename, original_ext, "html") do
        {Path.join(proj.base_url, name), Path.join(proj.dest, name)}
      end

    %__MODULE__{
      file: file,
      type: type,
      title: header[:title],
      tags: tags,
      data: data,
      date: datetime,
      url: url,
      output: output,
      template: header[:template],
      extras: extras
    }
  end

  @spec compact(t()) :: map()
  def compact(%__MODULE__{} = post) do
    post
    |> Map.drop(~w(__struct__ file data output type)a)
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
