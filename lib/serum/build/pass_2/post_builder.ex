defmodule Serum.Build.Pass2.PostBuilder do
  alias Serum.Result
  alias Serum.Fragment
  alias Serum.Post

  @spec run([Post.t()], map()) :: Result.t([Fragment.t()])
  def run(posts, proj) do
    posts
    |> Task.async_stream(Post, :to_fragment, [proj])
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate_values(:post_builder)
  end
end
