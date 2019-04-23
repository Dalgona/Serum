defmodule Serum.PostTest do
  use ExUnit.Case, async: true

  alias Serum.Post

  @sample_src "/path/to/src/"
  @sample_dest "/path/to/dest/"
  @sample_base "/mysite/"
  @sample_fmt "{YYYY}-{0M}-{0D}"

  @sample_proj %{
    src: @sample_src,
    dest: @sample_dest,
    base_url: @sample_base,
    date_format: @sample_fmt,
    preview_length: 12
  }

  @sample_header %{
    title: "Hello, world!",
    tags: ["lorem", "ipsum", "dolor"],
    date: "2019-04-23" |> Timex.parse!(@sample_fmt) |> Timex.to_datetime(:local)
  }

  test "new/4" do
    path = @sample_src <> "posts/2019-04-23-hello-world.md"
    html = "The quick brown fox jumps over the lazy dog.\n"
    post = Post.new(path, @sample_header, html, @sample_proj)

    assert %Post{
             file: ^path,
             title: "Hello, world!",
             date: "2019-04-23",
             raw_date: {{2019, 4, 23}, {0, 0, 0}},
             url: @sample_base <> "posts/2019-04-23-hello-world.html",
             html: ^html,
             output: @sample_dest <> "posts/2019-04-23-hello-world.html"
           } = post

    preview_len = String.length(post.preview)

    assert 12 <= preview_len and preview_len <= String.length(html)

    actual_tag_names = post.tags |> Enum.map(& &1.name) |> MapSet.new()
    expected_tag_names = MapSet.new(["lorem", "ipsum", "dolor"])

    assert actual_tag_names === expected_tag_names

    proj2 = %{@sample_proj | preview_length: 10_000_000}
    post2 = Post.new(path, @sample_header, html, proj2)

    assert String.trim(post2.preview) === String.trim(html)
  end

  test "compact/1" do
    post = %Post{
      file: "* DELETE ME *",
      title: "Hello, world!",
      date: "2019-04-23",
      raw_date: {{2019, 4, 23}, {0, 0, 0}},
      url: "/mysite/posts/2019-04-23-hello-world.html",
      html: "* DELETE ME *",
      preview: "Lorem ipsum dolor blah blah",
      output: "* DELETE ME *"
    }

    compact_post = Post.compact(post)

    refute Map.has_key?(compact_post, :__struct__)
    assert Enum.all?(compact_post, fn {_, v} -> v !== "* DELETE ME *" end)
    assert compact_post.type === :post
  end
end
