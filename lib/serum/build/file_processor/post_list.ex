defmodule Serum.Build.FileProcessor.PostList do
  @moduledoc false

  require Serum.V2.Result, as: Result
  import Serum.V2.Console, only: [put_msg: 2]
  alias Serum.Plugin.Client, as: PluginClient
  alias Serum.V2.BuildContext
  alias Serum.V2.Post
  alias Serum.V2.PostList
  alias Serum.V2.Tag

  @type tag_groups() :: [{Tag.t(), [Post.t()]}]
  @type tag_counts() :: [{Tag.t(), integer()}]

  @doc false
  @spec generate_lists([Post.t()], BuildContext.t()) :: Result.t({[PostList.t()], tag_counts()})
  def generate_lists(posts, context)
  def generate_lists([], _context), do: Result.return({[], []})

  def generate_lists(posts, context) do
    put_msg(:info, "Generating post lists...")

    tag_groups = group_posts_by_tag(posts)

    Result.run do
      lists = do_generate_lists(posts, tag_groups, context)
      lists <- PluginClient.generated_post_lists(lists)

      Result.return({List.flatten(lists), get_tag_counts(tag_groups)})
    end
  end

  @spec group_posts_by_tag([Post.t()], map()) :: tag_groups()
  defp group_posts_by_tag(posts, acc \\ %{})

  defp group_posts_by_tag([], acc) do
    Enum.map(acc, fn {tag, posts} -> {tag, Enum.reverse(posts)} end)
  end

  defp group_posts_by_tag([post | posts], acc1) do
    new_acc =
      Enum.reduce(post.tags, acc1, fn tag, acc2 ->
        acc2
        |> Map.get_and_update(tag, fn
          nil -> {nil, [post]}
          posts when is_list(posts) -> {posts, [post | posts]}
        end)
        |> elem(1)
      end)

    group_posts_by_tag(posts, new_acc)
  end

  @spec do_generate_lists([Post.t()], tag_groups(), BuildContext.t()) :: [[PostList.t()]]
  defp do_generate_lists(posts, tag_groups, context) do
    [{nil, posts} | tag_groups]
    |> Task.async_stream(fn {tag, grouped_posts} ->
      Serum.PostList.generate(tag, grouped_posts, context)
    end)
    |> Enum.map(&elem(&1, 1))
  end

  @spec get_tag_counts(tag_groups()) :: tag_counts()
  defp get_tag_counts(tags) do
    Enum.map(tags, fn {k, v} -> {k, Enum.count(v)} end)
  end
end
