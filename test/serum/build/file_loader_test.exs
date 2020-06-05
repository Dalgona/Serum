defmodule Serum.Build.FileLoaderTest do
  use ExUnit.Case, async: true
  import Serum.TestHelper
  alias Serum.Build.FileLoader
  alias Serum.Project

  setup do
    tmp_dir = get_tmp_dir("serum_test_")

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
    test "loads four kinds of files", %{tmp_dir: tmp_dir} do
      proj = Project.new(%{src: tmp_dir})

      assert {:ok, load_result} = FileLoader.load_files(proj)

      Enum.each([pages: 1, posts: 1, templates: 4, includes: 1], fn {k, v} ->
        assert length(load_result[k]) === v
      end)
    end

    test "fails when one or more sub tasks fail", %{tmp_dir: tmp_dir} do
      proj = Project.new(%{src: tmp_dir})

      File.rm_rf!(Path.join(tmp_dir, "pages"))

      {:error, {:enoent, _, _}} = FileLoader.load_files(proj)
    end
  end
end
