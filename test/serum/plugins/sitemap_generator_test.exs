defmodule Serum.Plugins.SitemapGeneratorTest do
  use ExUnit.Case
  import Serum.TestHelper
  alias Serum.GlobalBindings
  alias Serum.Plugins.SitemapGenerator, as: P
  alias Serum.Project
  alias Serum.V2.Page
  alias Serum.V2.Post

  setup_all do
    bindings = %{
      site: %{server_root: "http://example.com/"},
      all_pages: [%Page{url: "index.html"}],
      all_posts: [%Post{url: "posts/hello.html", date: Timex.local()}]
    }

    GlobalBindings.load(bindings)
    on_exit(fn -> GlobalBindings.load(%{}) end)

    :ok
  end

  setup do
    dir = get_tmp_dir("serum_test_")

    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)

    {:ok, dir: dir}
  end

  describe "build_succeeded/2" do
    test "generates items for posts by default", %{dir: dir} do
      {:ok, _} = P.build_succeeded(%Project{dest: dir}, [])
      sitemap = dir |> Path.join("sitemap.xml") |> File.read!()

      refute String.contains?(sitemap, "http://example.com/index.html")
      assert String.contains?(sitemap, "http://example.com/posts/hello.html")
    end

    test "generates items for pages", %{dir: dir} do
      {:ok, _} = P.build_succeeded(%Project{dest: dir}, for: :pages)
      sitemap = dir |> Path.join("sitemap.xml") |> File.read!()

      assert String.contains?(sitemap, "http://example.com/index.html")
      refute String.contains?(sitemap, "http://example.com/posts/hello.html")
    end

    test "generates items for both pages and posts", %{dir: dir} do
      {:ok, _} = P.build_succeeded(%Project{dest: dir}, for: [:pages, :posts])
      sitemap = dir |> Path.join("sitemap.xml") |> File.read!()

      assert String.contains?(sitemap, "http://example.com/index.html")
      assert String.contains?(sitemap, "http://example.com/posts/hello.html")
    end

    test "returns an error when failed to write a file", %{dir: dir} do
      File.chmod!(dir, 0o000)

      {:ok, _} = P.build_succeeded(%Project{dest: dir}, [])

      File.chmod!(dir, 0o755)
    end
  end
end
