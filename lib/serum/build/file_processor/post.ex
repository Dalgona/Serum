defmodule Serum.Build.FileProcessor.Post do
  @moduledoc false

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
    IO.puts("Processing post files...")

    files
    |> Task.async_stream(&process_post(&1, proj))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate_values(:file_processor)
    |> case do
      {:ok, posts} ->
        sorted_posts = Enum.sort(posts, &(&1.raw_date > &2.raw_date))

        {:ok, {sorted_posts, Enum.map(sorted_posts, &Post.compact/1)}}

      {:error, _} = error ->
        error
    end
  end

  @spec process_post(Serum.File.t(), Project.t()) :: Result.t(Post.t())
  defp process_post(file, proj) do
    import Serum.HeaderParser

    opts = [
      title: :string,
      tags: {:list, :string},
      date: :datetime
    ]

    required = [:title, :date]

    with {:ok, file2} <- Plugin.processing_post(file),
         {:ok, {header, rest}} <- parse_header(file2.in_data, opts, required) do
      header = %{
        header
        | date: header[:date] || Timex.to_datetime(Timex.zero(), :local)
      }

      post = Post.new(file2.src, header, Markdown.to_html(rest, proj), proj)

      Plugin.processed_post(post)
    else
      {:invalid, message} -> {:error, {message, file.src, 0}}
      {:error, _} = plugin_error -> plugin_error
    end
  end
end
