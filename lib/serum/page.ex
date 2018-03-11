defmodule Serum.Page do
  @moduledoc "This module defines Page struct."

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

  alias Serum.Result
  alias Serum.Fragment
  alias Serum.HeaderParser
  alias Serum.Renderer
  alias Serum.Template
  alias Serum.TemplateLoader

  defstruct [:file, :type, :title, :label, :group, :order, :url, :output, :data]

  @spec load(binary(), map()) :: Result.t(t())
  def load(path, proj) do
    with {:ok, file} <- File.open(path, [:read, :utf8]),
         {:ok, {header, data}} <- get_contents(file, path) do
      File.close(file)
      {:ok, create_struct(path, header, data, proj)}
    else
      {:error, reason} when is_atom(reason) -> {:error, {reason, path, 0}}
      {:error, _} = error -> error
    end
  end

  @spec get_contents(pid(), binary()) :: Result.t(map())
  defp get_contents(file, path) do
    opts = [
      title: :string,
      label: :string,
      group: :string,
      order: :integer
    ]

    required = [:title]

    with {:ok, header} <- HeaderParser.parse_header(file, path, opts, required),
         data when is_binary(data) <- IO.read(file, :all) do
      header = Map.put(header, :label, header[:label] || header.title)
      {:ok, {header, data}}
    else
      {:error, reason} when is_atom(reason) -> {:error, {reason, path, 0}}
      {:error, _} = error -> error
    end
  end

  @spec create_struct(binary(), map(), binary(), map()) :: t()
  defp create_struct(path, header, data, proj) do
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
    with {:ok, temp} <- preprocess(page),
         {:ok, html} <- render(temp, proj) do
      {:ok, Fragment.new(:page, page, html)}
    else
      {:error, _} = error -> error
    end
  end

  @spec preprocess(t()) :: Result.t(binary())
  defp preprocess(page)

  defp preprocess(%__MODULE__{type: ".md"} = page) do
    {:ok, Earmark.to_html(page.data)}
  end

  defp preprocess(%__MODULE__{type: ".html"} = page) do
    {:ok, page.data}
  end

  defp preprocess(%__MODULE__{type: ".html.eex"} = page) do
    case TemplateLoader.compile(page.data, :template) do
      {:ok, ast} ->
        template = Template.new(ast, :template, page.file)

        Renderer.render_fragment(template, [])

      {:ct_error, msg, line} ->
        {:error, {msg, page.file, line}}
    end
  end

  @spec render(binary(), map()) :: Result.t(binary())
  defp render(html, proj) do
    bindings = [contents: html]
    template = Template.get("page")

    case Renderer.render_fragment(template, bindings) do
      {:ok, rendered} ->
        {:ok, Renderer.process_links(rendered, proj.base_url)}

      {:error, _} = error ->
        error
    end
  end
end

defimpl Inspect, for: Serum.Page do
  def inspect(page, _opts), do: ~s(#Serum.Page<"#{page.title}">)
end
