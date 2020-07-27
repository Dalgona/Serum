defmodule Serum.Build.FileProcessor.PostTest do
  use Serum.Case
  require Serum.TestHelper
  import Serum.Build.FileProcessor.Post
  alias Serum.Project.Loader, as: ProjectLoader
  alias Serum.Template
  alias Serum.Template.Storage, as: TS
  alias Serum.V2
  alias Serum.V2.BuildContext
  alias Serum.V2.Error
  alias Serum.V2.Post

  setup_all do
    source_dir = fixture("proj/good/")
    dest_dir = "/path/to/dest/"
    {:ok, proj} = ProjectLoader.load(source_dir)
    context = %BuildContext{project: proj, source_dir: source_dir, dest_dir: dest_dir}
    template = Template.new("Hello, world!", "test", :template, "test.html.eex")

    TS.load(%{"test" => template}, :include)
    on_exit(fn -> TS.reset() end)

    {:ok, [context: context]}
  end

  describe "preprocess_posts/2 and process_posts/2" do
    test "process markdown posts", %{context: context} do
      file = read("posts/good-post.md")
      {:ok, {posts, [compact_post]}} = preprocess_posts([file], context)
      {:ok, [post]} = process_posts(posts, context)

      assert %Post{
               type: "md",
               title: "Test Post",
               date: %DateTime{
                 year: 2019,
                 month: 1,
                 day: 1,
                 hour: 12,
                 minute: 34,
                 second: 56
               },
               tags: [%{name: "tag1"}, %{name: "tag2"}]
             } = post

      assert_compact(compact_post)
    end

    test "process HTML-EEx posts", %{context: context} do
      file = read("posts/good-html.html.eex")
      {:ok, {posts, [compact_post]}} = preprocess_posts([file], context)
      {:ok, [post]} = process_posts(posts, context)

      assert %Post{
               type: "html",
               title: "Test HTML-EEx Post",
               date: %DateTime{
                 year: 2020,
                 month: 1,
                 day: 1,
                 hour: 0,
                 minute: 0,
                 second: 0
               },
               tags: [%{name: "serum"}, %{name: "test"}]
             } = post

      assert_compact(compact_post)
    end

    test "process markdown posts with simplified date", %{context: context} do
      file = read("posts/good-alternative-date.md")
      {:ok, {posts, [compact_post]}} = preprocess_posts([file], context)
      {:ok, [post]} = process_posts(posts, context)

      assert %Post{
               type: "md",
               title: "Test Post",
               date: %DateTime{year: 2019, month: 1, day: 1},
               tags: [%{name: "tag3"}, %{name: "tag4"}]
             } = post

      assert_compact(compact_post)
    end

    test "process markdown posts without any tag", %{context: context} do
      file = read("posts/good-minimal-header.md")
      {:ok, {posts, [compact_post]}} = preprocess_posts([file], context)
      {:ok, [post]} = process_posts(posts, context)

      assert %Post{
               type: "md",
               title: "Test Post",
               date: %DateTime{year: 2019, month: 1, day: 1},
               tags: []
             } = post

      assert_compact(compact_post)
    end

    test "fail when malformed posts are given", %{context: context} do
      files =
        fixture("posts")
        |> Path.join("bad-*.md")
        |> Path.wildcard()
        |> Enum.map(&%V2.File{src: &1})
        |> Enum.map(&V2.File.read/1)
        |> Enum.map(fn {:ok, file} -> file end)

      {:error, %Error{caused_by: errors}} = preprocess_posts(files, context)

      assert length(errors) === length(files)
    end

    test "fail when malformed EEx posts are given", %{context: context} do
      files =
        fixture("posts")
        |> Path.join("bad-*.html.eex")
        |> Path.wildcard()
        |> Enum.map(&%V2.File{src: &1})
        |> Enum.map(&V2.File.read/1)
        |> Enum.map(fn {:ok, file} -> file end)

      {:ok, {posts, _}} = preprocess_posts(files, context)
      {:error, %Error{caused_by: errors}} = process_posts(posts, context)

      assert length(errors) === length(files)
    end
  end

  defp read(path) do
    file = %V2.File{src: fixture(path)}
    {:ok, file} = V2.File.read(file)

    file
  end

  defp assert_compact(map) do
    refute map[:__struct__]
    refute map[:file]
    refute map[:html]
    refute map[:output]
    assert map.type === :post
  end
end
