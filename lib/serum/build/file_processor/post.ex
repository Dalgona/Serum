defmodule Serum.Build.FileProcessor.Post do
  @moduledoc false

  require Serum.Result, as: Result
  import Serum.IOProxy, only: [put_msg: 2]
  alias Serum.Error
  alias Serum.Markdown
  alias Serum.Plugin.Client, as: PluginClient
  alias Serum.Post
  alias Serum.Project
  alias Serum.Renderer
  alias Serum.Template
  alias Serum.Template.Compiler, as: TC

  @next_line_key "__serum__next_line__"

  @spec preprocess_posts([Serum.File.t()], Project.t()) :: Result.t({[Post.t()], [map()]})
  def preprocess_posts(files, proj)
  def preprocess_posts([], _proj), do: Result.return({[], []})

  def preprocess_posts(files, proj) do
    put_msg(:info, "Processing post files...")

    files
    |> Task.async_stream(&preprocess_post(&1, proj))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate("failed to preprocess posts:")
    |> case do
      {:ok, posts} ->
        sorted_posts = Enum.sort(posts, &(DateTime.compare(&1.date, &2.date) == :gt))

        Result.return({sorted_posts, Enum.map(sorted_posts, &Post.compact/1)})

      {:error, %Error{}} = error ->
        error
    end
  end

  @spec preprocess_post(Serum.File.t(), Project.t()) :: Result.t(Post.t())
  defp preprocess_post(file, proj) do
    import Serum.HeaderParser

    opts = [
      title: :string,
      tags: {:list, :string},
      date: :datetime,
      template: :string
    ]

    required = [:title, :date]

    Result.run do
      file2 <- PluginClient.processing_post(file)
      {header, extras, rest, next_line} <- parse_header(file2, opts, required)

      header = %{
        header
        | date: header[:date] || Timex.to_datetime(Timex.zero(), :local)
      }

      post = Post.new(file2, {header, extras}, rest, proj)

      post = %Post{
        post
        | extras: Map.put(post.extras, @next_line_key, next_line)
      }

      Result.return(post)
    end
  end

  @doc false
  @spec process_posts([Post.t()], Project.t()) :: Result.t([Post.t()])
  def process_posts(posts, proj)
  def process_posts([], _proj), do: Result.return([])

  def process_posts(posts, proj) do
    posts
    |> Task.async_stream(&process_post(&1, proj))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate("failed to process posts:")
    |> case do
      {:ok, posts} -> PluginClient.processed_posts(posts)
      {:error, %Error{}} = error -> error
    end
  end

  @spec process_post(Post.t(), Project.t()) :: Result.t(Post.t())
  defp process_post(post, proj) do
    Result.run do
      line = post.extras[@next_line_key] || 1
      ast <- TC.compile_string(post.data, line: line)
      template = Template.new(ast, post.file.src, :template, post.file)
      expanded_template <- TC.Include.expand(template)
      rendered <- Renderer.render_fragment(expanded_template, [])

      Result.return(%Post{post | data: process_data(rendered, post.type, proj)})
    else
      {:ct_error, msg, line} ->
        Result.fail(Simple, [msg], file: post.file, line: line)

      {:error, %Error{}} = error ->
        error
    end
  end

  @spec process_data(binary(), binary(), Project.t()) :: binary()
  defp process_data(data, type, proj)
  defp process_data(data, "md", proj), do: Markdown.to_html(data, proj)
  defp process_data(data, _type, _proj), do: data
end
