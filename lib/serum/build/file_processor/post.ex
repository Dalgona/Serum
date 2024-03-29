defmodule Serum.Build.FileProcessor.Post do
  @moduledoc false

  import Serum.IOProxy, only: [put_msg: 2]
  alias Serum.Markdown
  alias Serum.Plugin
  alias Serum.Post
  alias Serum.Project
  alias Serum.Result

  @doc false
  @spec process_posts([Serum.File.t()], Project.t()) :: Result.t({[Post.t()], [map()]})
  def process_posts(files, proj)
  def process_posts([], _proj), do: {:ok, {[], []}}

  def process_posts(files, proj) do
    put_msg(:info, "Processing post files...")

    result =
      files
      |> Task.async_stream(&process_post(&1, proj))
      |> Enum.map(&elem(&1, 1))
      |> Result.aggregate_values(:file_processor)

    with {:ok, posts} <- result,
         sorted_posts = Enum.sort(posts, &(&1.raw_date > &2.raw_date)),
         {:ok, posts2} <- Plugin.processed_posts(sorted_posts) do
      {:ok, {posts2, Enum.map(posts2, &Post.compact/1)}}
    else
      {:error, _} = error -> error
    end
  end

  @spec process_post(Serum.File.t(), Project.t()) :: Result.t(Post.t())
  defp process_post(file, proj) do
    import Serum.HeaderParser

    opts = [
      title: :string,
      tags: {:list, :string},
      date: :datetime,
      canonical_url: :string,
      template: :string
    ]

    required = [:title, :date]

    with {:ok, %{in_data: data} = file2} <- Plugin.processing_post(file),
         {:ok, {header, extras, rest}} <- parse_header(data, opts, required) do
      header = %{
        header
        | date: header[:date] || Timex.to_datetime(Timex.zero(), :local)
      }

      html = Markdown.to_html(rest, proj)
      post = Post.new(file2.src, {header, extras}, html, proj)

      Plugin.processed_post(post)
    else
      {:invalid, message} -> {:error, {message, file.src, 0}}
      {:error, _} = plugin_error -> plugin_error
    end
  end
end
