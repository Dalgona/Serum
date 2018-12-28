defmodule Serum.Build.Pass1.PostBuilder do
  import Serum.Util
  alias Serum.HeaderParser
  alias Serum.Result
  alias Serum.Post

  @spec run(map()) :: Result.t([Post.t()])
  def run(proj) do
    proj.src
    |> get_file_list()
    |> Enum.map(&Serum.File.read/1)
    |> Task.async_stream(&load_post(&1, proj))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate_values(:post_builder)
  end

  @spec get_file_list(binary()) :: [Serum.File.t()]
  defp get_file_list(src) do
    IO.puts("Collecting posts information...")
    post_dir = (src == "." && "posts") || Path.join(src, "posts")

    if File.exists?(post_dir) do
      [post_dir, "*.md"]
      |> Path.join()
      |> Path.wildcard()
      |> Enum.sort()
      |> Enum.map(&%Serum.File{src: &1})
    else
      warn("Cannot access `posts/'. No post will be generated.")
      []
    end
  end

  @spec load_post(Result.t(Serum.File.t()), map()) :: Result.t(Post.t())
  defp load_post(read_result, proj)
  defp load_post({:error, _} = error, _proj), do: error

  defp load_post({:ok, file}, proj) do
    opts = [
      title: :string,
      tags: {:list, :string},
      date: :datetime
    ]

    required = [:title]

    case HeaderParser.parse_header(file, opts, required) do
      {:ok, header, rest_data} ->
        header = %{
          header
          | date: header[:date] || Timex.to_datetime(Timex.zero(), :local)
        }

        {:ok, Post.new(file.src, header, Earmark.as_html!(rest_data), proj)}

      {:error, _} = error ->
        error
    end
  end
end
