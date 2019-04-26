defmodule Serum.Build.FileLoaderTest do
  use ExUnit.Case, async: true
  require Serum.TestHelper
  import Serum.TestHelper, only: :macros
  alias Serum.Build.FileLoader

  setup do
    uniq = Base.url_encode64(:crypto.strong_rand_bytes(6))
    tmp_dir = Path.expand("serum_test_" <> uniq, System.tmp_dir!())

    File.mkdir_p!(tmp_dir)

    ["pages", "posts", "templates", "includes"]
    |> Enum.map(&Path.join(tmp_dir, &1))
    |> Enum.each(&File.mkdir_p!/1)

    [
      "pages/test-page.md",
      "posts/2019-01-01-test-post.md",
      "templates/base.html.eex",
      "templates/page.html.eex",
      "templates/post.html.eex",
      "templates/list.html.eex",
      "includes/foo.html.eex"
    ]
    |> Enum.map(&Path.join(tmp_dir, &1))
    |> Enum.each(&File.touch!/1)

    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    {:ok, [tmp_dir: tmp_dir]}
  end

  describe "load_files/1" do
    test "successfully loaded files", %{tmp_dir: tmp_dir} do
      {:ok, %{pages: pages, posts: posts, templates: temps, includes: incls}} =
        mute_stdio do
          FileLoader.load_files(tmp_dir)
        end

      assert length(pages) === 1
      assert length(posts) === 1
      assert length(temps) === 4
      assert length(incls) === 1
    end

    test "ignore optional directories", %{tmp_dir: tmp_dir} do
      File.rm_rf!(Path.join(tmp_dir, "posts"))
      File.rm_rf!(Path.join(tmp_dir, "includes"))

      {:ok, %{pages: pages, posts: [], templates: temps, includes: []}} =
        mute_stdio do
          FileLoader.load_files(tmp_dir)
        end

      assert length(pages) === 1
      assert length(temps) === 4
    end

    test "pages directory is missing", %{tmp_dir: tmp_dir} do
      File.rm_rf!(Path.join(tmp_dir, "pages"))

      {:error, {:enoent, _, _}} =
        mute_stdio do
          FileLoader.load_files(tmp_dir)
        end
    end

    test "some templates are missing", %{tmp_dir: tmp_dir} do
      File.rm_rf!(Path.join(tmp_dir, "templates/base.html.eex"))

      {:error, {_, [{:error, {:enoent, _, _}} | _]}} =
        mute_stdio do
          FileLoader.load_files(tmp_dir)
        end
    end
  end
end
