defmodule Serum.Post do
  @moduledoc """
  Defines a struct representing a blog post page.

  ## Fields

  * `file`: Source path
  * `title`: Post title
  * `date`: Post date (formatted)
  * `raw_date`: Post date (erlang tuple style)
  * `tags`: A list of tags
  * `url`: Absolute URL of the blog post in the website
  * `html`: Post contents converted into HTML
  * `preview`: Preview text of the post
  * `output`: Destination path
  """

  alias Serum.Fragment
  alias Serum.Plugin
  alias Serum.Renderer
  alias Serum.Result
  alias Serum.Tag
  alias Serum.Template

  @type t :: %__MODULE__{
          file: binary(),
          title: binary(),
          date: binary(),
          raw_date: {:calendar.date(), :calendar.time()},
          tags: [Tag.t()],
          url: binary(),
          html: binary(),
          preview: binary(),
          output: binary()
        }

  defstruct [
    :file,
    :title,
    :date,
    :raw_date,
    :tags,
    :url,
    :html,
    :preview,
    :output
  ]

  @metadata_keys [:title, :date, :raw_date, :preview, :tags, :url]

  @spec new(binary(), map(), binary(), map()) :: t()
  def new(path, header, html, proj) do
    tags = Tag.batch_create(header[:tags] || [], proj)
    datetime = header[:date]
    date_str = Timex.format!(datetime, proj.date_format)
    raw_date = datetime |> Timex.to_erl()
    preview = generate_preview(html, proj.preview_length)

    filename =
      path
      |> String.replace_suffix("md", "html")
      |> Path.relative_to(proj.src)

    %__MODULE__{
      file: path,
      title: header.title,
      tags: tags,
      html: html,
      preview: preview,
      raw_date: raw_date,
      date: date_str,
      url: Path.join(proj.base_url, filename),
      output: Path.join(proj.dest, filename)
    }
  end

  @spec generate_preview(binary(), non_neg_integer()) :: binary()
  defp generate_preview(html, length)

  defp generate_preview(_html, length) when length <= 0, do: ""

  defp generate_preview(html, length) do
    text =
      html
      |> Floki.text(sep: " ")
      |> String.trim()
      |> String.replace(~r/\s+/, " ")

    if String.length(text) <= length do
      text
    else
      String.slice(text, 0, length) <> "\u2026"
    end
  end

  @spec to_fragment(t(), map()) :: Result.t(Fragment.t())
  def to_fragment(post, proj) do
    metadata =
      post
      |> Map.take(@metadata_keys)
      |> Map.put(:type, :post)

    case to_html(post, metadata, proj) do
      {:ok, html} ->
        fragment = Fragment.new(post.file, post.output, metadata, html)

        Plugin.rendered_fragment(fragment)

      {:error, _} = error ->
        error
    end
  end

  @spec to_html(t(), map(), map()) :: Result.t(binary())
  def to_html(%__MODULE__{} = post, metadata, proj) do
    bindings = [page: metadata, contents: post.html]
    template = Template.get("post")

    case Renderer.render_fragment(template, bindings) do
      {:ok, rendered} ->
        {:ok, Renderer.process_links(rendered, proj.base_url)}

      {:error, _} = error ->
        error
    end
  end

  defimpl Fragment.Source do
    alias Serum.Post
    alias Serum.Project
    alias Serum.Result

    @spec to_fragment(Post.t(), Project.t()) :: Result.t(Fragment.t())
    def to_fragment(post, proj), do: Post.to_fragment(post, proj)
  end
end
