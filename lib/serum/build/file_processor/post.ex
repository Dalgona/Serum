defmodule Serum.Build.FileProcessor.Post do
  @moduledoc false

  require Serum.V2.Result, as: Result
  import Serum.V2.Console, only: [put_msg: 2]
  alias Serum.Build.FileProcessor.Content
  alias Serum.Plugin.Client, as: PluginClient
  alias Serum.V2
  alias Serum.V2.BuildContext
  alias Serum.V2.Error
  alias Serum.V2.Post

  @spec preprocess_posts([V2.File.t()], BuildContext.t()) :: Result.t({[Post.t()]})
  def preprocess_posts(files, context)
  def preprocess_posts([], _context), do: Result.return({[], []})

  def preprocess_posts(files, context) do
    put_msg(:info, "Processing post files...")

    Result.run do
      files <- PluginClient.processing_posts(files)
      posts <- do_preprocess_posts(files, context)
      sorted_posts = Enum.sort(posts, &(DateTime.compare(&1.date, &2.date) == :gt))

      Result.return(sorted_posts)
    end
  end

  @spec do_preprocess_posts([V2.File.t()], BuildContext.t()) :: Result.t([Post.t()])
  defp do_preprocess_posts(files, context) do
    files
    |> Task.async_stream(&preprocess_post(&1, context))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate("failed to preprocess posts:")
  end

  @spec preprocess_post(V2.File.t(), BuildContext.t()) :: Result.t(Post.t())
  defp preprocess_post(file, context) do
    import Serum.HeaderParser
    alias Serum.HeaderParser.ParseResult

    opts = [
      title: :string,
      tags: {:list, :string},
      date: :datetime,
      template: :string
    ]

    Result.run do
      %ParseResult{} = header <- parse_header(file, opts, ~w(title date)a)
      Result.return(Serum.Post.new(file, header, context))
    end
  end

  @doc false
  @spec process_posts([Post.t()], BuildContext.t()) :: Result.t([Post.t()])
  def process_posts(posts, context)
  def process_posts([], _context), do: Result.return([])

  def process_posts(posts, context) do
    posts
    |> Task.async_stream(&process_post(&1, context))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate("failed to process posts:")
    |> case do
      {:ok, posts} -> PluginClient.processed_posts(posts)
      {:error, %Error{}} = error -> error
    end
  end

  @spec process_post(Post.t(), BuildContext.t()) :: Result.t(Post.t())
  defp process_post(post, context) do
    process_opts = [file: post.source, line: post.extras["__serum__next_line__"]]

    case Content.process_content(post.data, post.type, context, process_opts) do
      {:ok, data} -> Result.return(%Post{post | data: data})
      {:error, %Error{}} = error -> error
    end
  end
end
