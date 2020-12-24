defmodule Serum.Plugins.SitemapGeneratorTest do
  use Serum.Case
  alias Serum.Plugins.SitemapGenerator, as: P
  alias Serum.V2.BuildContext
  alias Serum.V2.Page
  alias Serum.V2.Post
  alias Serum.V2.Project

  setup_all do
    project = %Project{base_url: URI.parse("https://example.com/")}
    pages = [%Page{url: "index.html"}]
    posts = [%Post{url: "posts/hello.html", date: Timex.local()}]

    {:ok, project: project, pages: pages, posts: posts}
  end

  setup do
    dir = get_tmp_dir("serum_test_")

    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)

    {:ok, dir: dir}
  end

  describe "init/1" do
    test "initializes the plugin state" do
      assert {:ok, %{args: [], pages: [], posts: []}} = P.init([])
    end
  end

  describe "processed_posts/2" do
    test "updates the state if `:for` argument is not given", ctx do
      posts = ctx.posts
      state = %{args: [], pages: [], posts: []}

      assert {:ok, {^posts, %{posts: ^posts}}} = P.processed_posts(posts, state)
    end

    test "updates the state if `:posts` is in `args[:for]`", ctx do
      posts = ctx.posts
      state = %{args: [for: [:posts]], pages: [], posts: []}

      assert {:ok, {^posts, %{posts: ^posts}}} = P.processed_posts(posts, state)
    end

    test "leaves the state unmodified if `:posts` is not in `args[:for]`", ctx do
      posts = ctx.posts
      state = %{args: [for: [:pages]], pages: [], posts: []}

      assert {:ok, {^posts, %{posts: []}}} = P.processed_posts(posts, state)
    end
  end

  describe "build_succeeded/2" do
    test "generates a sitemap file", ctx do
      context = %BuildContext{dest_dir: ctx.dir, project: ctx.project}
      state = %{args: [], pages: ctx.pages, posts: ctx.posts}

      assert {:ok, _} = P.build_succeeded(context, state)

      sitemap = ctx.dir |> Path.join("sitemap.xml") |> File.read!()

      assert String.contains?(sitemap, "https://example.com/index.html")
      assert String.contains?(sitemap, "https://example.com/posts/hello.html")
    end
  end
end
