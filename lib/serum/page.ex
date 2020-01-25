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

  require Serum.Result, as: Result
  alias Serum.Error
  alias Serum.Fragment
  alias Serum.Renderer
  alias Serum.Template
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
    type = get_type(filename)

    {url, output} =
      with name <- String.replace_suffix(filename, type, ".html") do
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

  @spec get_type(binary) :: binary()
  defp get_type(filename) do
    case Path.extname(filename) do
      ".eex" ->
        filename
        |> Path.basename(".eex")
        |> Path.extname()
        |> Kernel.<>(".eex")

      ext ->
        ext
    end
  end

  @spec to_fragment(t()) :: Result.t(Fragment.t())
  def to_fragment(page) do
    metadata = compact(page)
    template_name = page.template || "page"
    bindings = [page: metadata, contents: page.data]

    with %Template{} = template <- TS.get(template_name, :template),
         {:ok, html} <- Renderer.render_fragment(template, bindings) do
      Fragment.new(page.file, page.output, metadata, html)
    else
      nil -> Result.fail(Simple, ["the template \"#{template_name}\" is not available"])
      {:error, %Error{}} = error -> error
    end
  end

  defimpl Fragment.Source do
    alias Serum.Page
    alias Serum.Result

    @spec to_fragment(Page.t()) :: Result.t(Fragment.t())
    def to_fragment(page) do
      Page.to_fragment(page)
    end
  end
end
