defmodule Serum.Build.FileProcessor.PostListTest do
  use ExUnit.Case, async: true
  alias Serum.Build.FileProcessor.PostList, as: ListGenerator
  alias Serum.V2.Tag

  setup_all do
    tags1 =
      ~w(tag1 tag2 tag3)
      |> Enum.map(&%Tag{name: &1, path: "/tags/#{&1}/"})
      |> Stream.cycle()

    tags2 = Stream.drop(tags1, 1)

    compact_posts =
      [1..30, tags1, tags2]
      |> Enum.zip()
      |> Enum.map(fn {n, t1, t2} ->
        %{
          title: "Test Post #{n}",
          tags: Enum.sort([t1, t2])
        }
      end)

    proj_template = %{
      src: "/path/to/src/",
      dest: "/path/to/dest/",
      base_url: "/",
      list_title_all: "All Posts",
      list_title_tag: "Posts Tagged ~s",
      posts_per_page: 5
    }

    {:ok, [compact_posts: compact_posts, proj_template: proj_template]}
  end

  describe "generate_lists/2" do
    test "no pagination", ctx do
      posts = ctx.compact_posts
      proj = Map.put(ctx.proj_template, :pagination, false)
      {:ok, {lists, counts}} = ListGenerator.generate_lists(posts, proj)

      # (num_of_tags + 1) * (index + page_1)
      assert length(lists) === (3 + 1) * 2
      assert length(counts) === 3

      Enum.each(counts, fn {_, n} -> assert n === 20 end)

      [all1, all2 | lists2] = lists

      Enum.each(lists2, fn list ->
        assert length(list.posts) === 20
        assert String.starts_with?(list.title, "Posts Tagged")
      end)

      Enum.each([all1, all2], fn list ->
        assert length(list.posts) === 30
        assert list.title === "All Posts"
      end)
    end

    test "chunk every 5 posts", ctx do
      posts = ctx.compact_posts
      proj = Map.put(ctx.proj_template, :pagination, true)
      {:ok, {lists, counts}} = ListGenerator.generate_lists(posts, proj)

      # num_of_tags * (index + page_1_to_4) + 1 * (index + page_1_to_6)
      assert length(lists) === 3 * (1 + 4) + (1 + 6)
      assert length(counts) === 3

      Enum.each(counts, fn {_, n} -> assert n === 20 end)

      initial_state = %{
        nil => 0,
        "tag1" => 0,
        "tag2" => 0,
        "tag3" => 0
      }

      state =
        Enum.reduce(lists, initial_state, fn list, acc ->
          assert length(list.posts) === 5
          check_list(list)
          Map.update(acc, list.tag && list.tag.name, 0, fn x -> x + 1 end)
        end)

      assert state[nil] === 7
      assert state["tag1"] === 5
      assert state["tag2"] === 5
      assert state["tag3"] === 5
    end
  end

  defp check_list(list) do
    if is_nil(list.tag) do
      assert list.title === "All Posts"
    else
      assert String.starts_with?(list.title, "Posts Tagged")
    end
  end
end
