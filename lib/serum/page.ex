defmodule Serum.Page do
  @moduledoc """
  Defines a struct describing a normal page.

  ## Fields
  * `file`: Source file
  * `type`: Type of source file
  * `title`: Page title
  * `label`: Page label
  * `group`: A group the page belongs to
  * `order`: Order of the page within its group
  * `url`: Absolute URL of the page within the website
  * `output`: Destination path
  * `data`: Source data
  * `extras`: A map for storing arbitrary key-value data
  * `template`: Name of custom template or `nil`
  """

  @type t :: %__MODULE__{
          file: Serum.File.t(),
          type: binary(),
          title: binary(),
          label: binary(),
          group: binary(),
          order: integer(),
          url: binary(),
          output: binary(),
          data: binary(),
          extras: map(),
          template: binary() | nil
        }

  require Serum.V2.Result, as: Result
  alias Serum.Fragment
  alias Serum.Renderer
  alias Serum.Template.Storage, as: TS

  defstruct [
    :file,
    :type,
    :title,
    :label,
    :group,
    :order,
    :url,
    :output,
    :data,
    :extras,
    :template
  ]

  @spec new(Serum.File.t(), {map(), map()}, binary(), map()) :: t()
  def new(file, {header, extras}, data, proj) do
    page_dir = (proj.src == "." && "pages") || Path.join(proj.src, "pages")
    filename = Path.relative_to(file.src, page_dir)
    {type, original_ext} = get_type(filename)

    {url, output} =
      with name <- String.replace_suffix(filename, original_ext, "html") do
        {Path.join(proj.base_url, name), Path.join(proj.dest, name)}
      end

    __MODULE__
    |> struct(header)
    |> Map.merge(%{
      file: file,
      type: type,
      url: url,
      output: output,
      data: data,
      extras: extras
    })
  end

  @spec compact(t()) :: map()
  def compact(%__MODULE__{} = page) do
    page
    |> Map.drop(~w(__struct__ data file output type)a)
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

  @spec to_fragment(t()) :: Result.t(Fragment.t())
  def to_fragment(page) do
    metadata = compact(page)
    template_name = page.template || "page"
    bindings = [page: metadata, contents: page.data]

    Result.run do
      template <- TS.get(template_name, :template)
      html <- Renderer.render_fragment(template, bindings)

      Fragment.new(page.file, page.output, metadata, html)
    end
  end

  defimpl Fragment.Source do
    alias Serum.Fragment
    alias Serum.Page
    alias Serum.V2.Result

    @spec to_fragment(Page.t()) :: Result.t(Fragment.t())
    def to_fragment(page) do
      Page.to_fragment(page)
    end
  end
end
