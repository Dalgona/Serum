defmodule Serum.Build.Pass1.PostBuilder do
  import Serum.Util
  alias Serum.HeaderParser
  alias Serum.Result
  alias Serum.Post

  @spec run(map()) :: Result.t([Post.t()])
  def run(proj) do
    proj.src
    |> load_file_list()
    |> Task.async_stream(&load_post(&1, proj))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate_values(:post_builder)
  end

  @spec load_file_list(binary()) :: [binary()]
  defp load_file_list(src) do
    IO.puts("Collecting posts information...")
    post_dir = (src == "." && "posts") || Path.join(src, "posts")

    if File.exists?(post_dir) do
      [post_dir, "*.md"]
      |> Path.join()
      |> Path.wildcard()
      |> Enum.sort()
    else
      warn("Cannot access `posts/'. No post will be generated.")
      []
    end
  end

  @spec load_post(binary(), map()) :: Result.t(Post.t())
  defp load_post(path, proj) do
    with {:ok, file} <- File.open(path, [:read, :utf8]),
         {:ok, {header, data}} <- get_contents(file, path) do
      File.close(file)
      {:ok, Post.create_struct(path, header, data, proj)}
    else
      {:error, reason} when is_atom(reason) -> {:error, {reason, path, 0}}
      {:error, _} = error -> error
    end
  end

  @spec get_contents(pid(), binary()) :: Result.t(map())
  defp get_contents(file, path) do
    opts = [
      title: :string,
      tags: {:list, :string},
      date: :datetime
    ]

    required = [:title]

    with {:ok, header} <- HeaderParser.parse_header(file, path, opts, required),
         data when is_binary(data) <- IO.read(file, :all) do
      header = %{
        header
        | date: header[:date] || Timex.to_datetime(Timex.zero(), :local)
      }

      {:ok, {header, data}}
    else
      {:error, reason} when is_atom(reason) -> {:error, {reason, path, 0}}
      {:error, _} = error -> error
    end
  end
end
