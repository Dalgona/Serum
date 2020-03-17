defmodule Serum.Page do
  @moduledoc false

  _moduledocp = """
  Defines functions internally used by Serum to create and manipulate
  `Serum.V2.Page` structs.
  """

  alias Serum.V2
  alias Serum.V2.Page

  @spec new(V2.File.t(), {map(), map()}, binary(), map()) :: Page.t()
  def new(source, {header, extras}, data, proj) do
    page_dir = (proj.src == "." && "pages") || Path.join(proj.src, "pages")
    filename = Path.relative_to(source.src, page_dir)
    {type, original_ext} = get_type(filename)

    {url, dest} =
      with name <- String.replace_suffix(filename, original_ext, "html") do
        {Path.join(proj.base_url, name), Path.join(proj.dest, name)}
      end

    %Page{
      source: source,
      dest: dest,
      type: type,
      title: header[:title],
      label: header[:label],
      group: header[:group],
      order: header[:order],
      url: url,
      data: data,
      template: header[:template],
      extras: extras
    }
  end

  @spec compact(Page.t()) :: map()
  def compact(%Page{} = page) do
    page
    |> Map.drop(~w(__struct__ source dest type data)a)
    |> Map.put(:type, :page)
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
