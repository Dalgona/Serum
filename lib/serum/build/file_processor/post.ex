defmodule Serum.Build.FileProcessor.Post do
  @moduledoc false

  require Serum.Result, as: Result
  import Serum.IOProxy, only: [put_msg: 2]
  alias Serum.Markdown
  alias Serum.Plugin.Client, as: PluginClient
  alias Serum.Post
  alias Serum.Project

  @doc false
  @spec process_posts([Serum.File.t()], Project.t()) :: Result.t({[Post.t()], [map()]})
  def process_posts(files, proj)
  def process_posts([], _proj), do: Result.return({[], []})

  def process_posts(files, proj) do
    put_msg(:info, "Processing post files...")

    result =
      files
      |> Task.async_stream(&process_post(&1, proj))
      |> Enum.map(&elem(&1, 1))
      |> Result.aggregate("failed to process posts:")

    Result.run do
      posts <- result
      sorted_posts = Enum.sort(posts, &(DateTime.compare(&1.date, &2.date) == :gt))
      posts2 <- PluginClient.processed_posts(sorted_posts)

      Result.return({posts2, Enum.map(posts2, &Post.compact/1)})
    end
  end

  @spec process_post(Serum.File.t(), Project.t()) :: Result.t(Post.t())
  defp process_post(file, proj) do
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
      {header, extras, rest, _next_line} <- parse_header(file2, opts, required)

      header = %{
        header
        | date: header[:date] || Timex.to_datetime(Timex.zero(), :local)
      }

      html = Markdown.to_html(rest, proj)
      post = Post.new(file2, {header, extras}, html, proj)

      PluginClient.processed_post(post)
    end
  end
end
