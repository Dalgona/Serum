defmodule Serum.Post do
  @moduledoc """
  Defines a struct representing a blog post page.

  ## Fields

  * `file`: Source file
  * `title`: Post title
  * `date`: A `DateTime` struct representing the post date
  * `tags`: A list of tags
  * `url`: Absolute URL of the blog post in the website
  * `html`: Post contents converted into HTML
  * `preview`: Preview text of the post
  * `output`: Destination path
  * `extras`: A map for storing arbitrary key-value data
  * `template`: Name of custom template or `nil`
  """

  require Serum.Result, as: Result
  alias Serum.Error
  alias Serum.Fragment
  alias Serum.Post.PreviewGenerator
  alias Serum.Renderer
  alias Serum.Tag
  alias Serum.Template
  alias Serum.Template.Storage, as: TS

  @type t :: %__MODULE__{
          file: Serum.File.t(),
          title: binary(),
          date: DateTime.t(),
          tags: [Tag.t()],
          url: binary(),
          html: binary(),
          preview: binary(),
          output: binary(),
          extras: map(),
          template: binary() | nil
        }

  defstruct [
    :file,
    :title,
    :date,
    :tags,
    :url,
    :html,
    :preview,
    :output,
    :extras,
    :template
  ]

  @spec new(Serum.File.t(), {map(), map()}, binary(), map()) :: t()
  def new(file, {header, extras}, html, proj) do
    tags = Tag.batch_create(header[:tags] || [], proj)
    datetime = header[:date]
    preview = PreviewGenerator.generate_preview(html, proj.preview_length)

    filename =
      file.src
      |> String.replace_suffix("md", "html")
      |> Path.relative_to(proj.src)

    %__MODULE__{
      file: file,
      title: header[:title],
      tags: tags,
      html: html,
      preview: preview,
      date: datetime,
      url: Path.join(proj.base_url, filename),
      output: Path.join(proj.dest, filename),
      template: header[:template],
      extras: extras
    }
  end

  @spec compact(t()) :: map()
  def compact(%__MODULE__{} = post) do
    post
    |> Map.drop(~w(__struct__ file html output)a)
    |> Map.put(:type, :post)
  end

  @spec to_fragment(t()) :: Result.t(Fragment.t())
  def to_fragment(post) do
    metadata = compact(post)
    template_name = post.template || "post"
    bindings = [page: metadata, contents: post.html]

    with %Template{} = template <- TS.get(template_name, :template),
         {:ok, html} <- Renderer.render_fragment(template, bindings) do
      Fragment.new(post.file, post.output, metadata, html)
    else
      nil -> Result.fail(Simple, ["the template \"#{template_name}\" is not available"])
      {:error, %Error{}} = error -> error
    end
  end

  defimpl Fragment.Source do
    alias Serum.Post
    alias Serum.Result

    @spec to_fragment(Post.t()) :: Result.t(Fragment.t())
    def to_fragment(post) do
      Post.to_fragment(post)
    end
  end
end
