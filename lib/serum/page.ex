defmodule Serum.Page do
  @moduledoc false

  _moduledocp = """
  Defines functions internally used by Serum to create and manipulate
  `Serum.V2.Page` structs.
  """

  alias Serum.HeaderParser.ParseResult
  alias Serum.V2
  alias Serum.V2.BuildContext
  alias Serum.V2.Page

  @spec new(V2.File.t(), ParseResult.t(), BuildContext.t()) :: Page.t()
  def new(source, %ParseResult{} = header, %BuildContext{} = context) do
    page_dir = (context.source_dir == "." && "pages") || Path.join(context.source_dir, "pages")
    filename = Path.relative_to(source.src, page_dir)
    {type, original_ext} = get_type(filename)

    {url, dest} =
      with name <- String.replace_suffix(filename, original_ext, "html") do
        {Path.join(context.project.base_url, name), Path.join(context.dest_dir, name)}
      end

    %Page{
      source: source,
      dest: dest,
      type: type,
      title: header.data[:title],
      label: header.data[:label] || header.data[:title],
      group: header.data[:group],
      order: header.data[:order],
      url: url,
      data: header.rest,
      template: header.data[:template],
      extras: Map.put(header.extras, "__serum__next_line__", header.next_line)
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
