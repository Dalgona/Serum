defmodule Serum.Page do
  @moduledoc """
  Defines a struct describing a normal page.

  ## Fields
  * `file`: Source path
  * `type`: Type of source file
  * `title`: Page title
  * `label`: Page label
  * `group`: A group the page belongs to
  * `order`: Order of the page within its group
  * `url`: Absolute URL of the page within the website
  * `output`: Destination path
  * `data`: Source data
  """

  @type t :: %__MODULE__{
          file: binary(),
          type: binary(),
          title: binary(),
          label: binary(),
          group: binary(),
          order: integer(),
          url: binary(),
          output: binary(),
          data: binary()
        }

  alias Serum.Fragment
  alias Serum.Plugin
  alias Serum.Renderer
  alias Serum.Result
  alias Serum.Template
  alias Serum.Template.Compiler, as: TC

  defstruct [:file, :type, :title, :label, :group, :order, :url, :output, :data]

  @spec new(binary(), map(), binary(), map()) :: t()
  def new(path, header, data, proj) do
    page_dir = (proj.src == "." && "pages") || Path.join(proj.src, "pages")
    filename = Path.relative_to(path, page_dir)
    type = get_type(filename)

    {url, output} =
      with name <- String.replace_suffix(filename, type, ".html") do
        {Path.join(proj.base_url, name), Path.join(proj.dest, name)}
      end

    __MODULE__
    |> struct(header)
    |> Map.merge(%{
      file: path,
      type: type,
      url: url,
      output: output,
      data: data
    })
  end

  @spec compact(t()) :: map()
  def compact(%__MODULE__{} = page) do
    page
    |> Map.drop(~w(__struct__ data file output type)a)
    |> Map.put(:type, :page)
  end

  @spec get_type(binary) :: binary
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

  @spec to_fragment(t(), map()) :: Result.t(Fragment.t())
  def to_fragment(page, proj) do
    metadata = compact(page)

    with {:ok, temp} <- preprocess(page),
         {:ok, html} <- render(temp, metadata, proj) do
      fragment = Fragment.new(page.file, page.output, metadata, html)

      Plugin.rendered_fragment(fragment)
    else
      {:error, _} = error -> error
    end
  end

  @spec preprocess(t()) :: Result.t(binary())
  defp preprocess(page)

  defp preprocess(%__MODULE__{type: ".md"} = page) do
    {:ok, Earmark.as_html!(page.data)}
  end

  defp preprocess(%__MODULE__{type: ".html"} = page) do
    {:ok, page.data}
  end

  defp preprocess(%__MODULE__{type: ".html.eex"} = page) do
    case TC.compile_string(page.data, :template) do
      {:ok, ast} ->
        template = Template.new(ast, :template, page.file)

        Renderer.render_fragment(template, [])

      {:ct_error, msg, line} ->
        {:error, {msg, page.file, line}}
    end
  end

  @spec render(binary(), map(), map()) :: Result.t(binary())
  defp render(html, metadata, proj) do
    bindings = [page: metadata, contents: html]
    template = Template.get("page")

    case Renderer.render_fragment(template, bindings) do
      {:ok, rendered} ->
        {:ok, Renderer.process_links(rendered, proj.base_url)}

      {:error, _} = error ->
        error
    end
  end

  defimpl Fragment.Source do
    alias Serum.Page
    alias Serum.Project
    alias Serum.Result

    @spec to_fragment(Page.t(), Project.t()) :: Result.t(Fragment.t())
    def to_fragment(page, proj), do: Page.to_fragment(page, proj)
  end
end
