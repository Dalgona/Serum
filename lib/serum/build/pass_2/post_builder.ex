defmodule Serum.Build.Pass2.PostBuilder do
  @moduledoc """
  During pass 2, PostBuilder does the following:

  1. Loops through the list of all blog posts. Renders the full HTML page of a
    blog post for each `Serum.Post` object in the list.
  """

  alias Serum.Result
  alias Serum.Fragment
  alias Serum.Post

  @doc "Starts the second pass of PostBuilder."
  @spec run([Post.t()], map()) :: Result.t()
  def run(posts, proj) do
    result = launch(posts, proj)
    Result.aggregate_values(result, :post_builder)
  end

  @spec launch([Post.t()], map()) :: [Result.t(Fragment.t())]
  defp launch(files, proj) do
    files
    |> Task.async_stream(Post, :to_fragment, [proj])
    |> Enum.map(&elem(&1, 1))
  end
end
