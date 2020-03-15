defmodule Serum.Build.FileProcessor.Post do
  @moduledoc false

  require Serum.V2.Result, as: Result
  import Serum.V2.Console, only: [put_msg: 2]
  alias Serum.Build.FileProcessor.Content
  alias Serum.Plugin.Client, as: PluginClient
  alias Serum.Project
  alias Serum.V2
  alias Serum.V2.Error
  alias Serum.V2.Post

  @next_line_key "__serum__next_line__"

  @spec preprocess_posts([V2.File.t()], Project.t()) :: Result.t({[Post.t()], [map()]})
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

        Result.return({sorted_posts, Enum.map(sorted_posts, &Serum.Post.compact/1)})

      {:error, %Error{}} = error ->
        error
    end
  end

  @spec preprocess_post(V2.File.t(), Project.t()) :: Result.t(Post.t())
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

      post = Serum.Post.new(file2, {header, extras}, rest, proj)

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
    process_opts = [file: post.source, line: post.extras[@next_line_key]]

    case Content.process_content(post.data, post.type, proj, process_opts) do
      {:ok, data} -> Result.return(%Post{post | data: data})
      {:error, %Error{}} = error -> error
    end
  end
end
