defmodule Serum.Build.FileLoader.PostsTest do
  use ExUnit.Case
  import Serum.Build.FileLoader.Posts
  import Serum.TestHelper
  alias Serum.Plugin

  "plugins/failing_plugin_1.ex"
  |> fixture()
  |> Code.require_file()

  describe "load/2" do
    setup do
      tmp_dir = get_tmp_dir("serum_test_")

      File.mkdir_p!(tmp_dir)

      on_exit(fn ->
        File.rm_rf!(tmp_dir)
        Plugin.load_plugins([])
      end)

      {:ok, tmp_dir: tmp_dir}
    end

    test "loads post files", %{tmp_dir: tmp_dir} do
      posts_dir = Path.join(tmp_dir, "posts")

      make_files(posts_dir)

      assert {:ok, posts} = load(tmp_dir, "posts")
      assert 3 === length(posts)
    end

    test "does not fail even if the posts directory does not exist", %{tmp_dir: tmp_dir} do
      assert {:ok, []} === load(tmp_dir, "non_existent_directory")
    end

    test "fails when some files cannot be loaded", %{tmp_dir: tmp_dir} do
      posts_dir = Path.join(tmp_dir, "posts")
      foo = Path.join(posts_dir, "foo.md")

      make_files(posts_dir)
      File.chmod!(foo, 0o000)

      assert {:error, _} = load(tmp_dir, "posts")

      File.chmod!(foo, 0o644)
    end

    test "fails when the loaded plugin fails", %{tmp_dir: tmp_dir} do
      posts_dir = Path.join(tmp_dir, "posts")

      make_files(posts_dir)

      {:ok, _} = Plugin.load_plugins([Serum.FailingPlugin1])

      assert {:error, _} = load(tmp_dir, "posts")
    end
  end

  defp make_files(dir) do
    File.mkdir_p!(dir)

    ~w(foo bar baz)
    |> Enum.map(&(&1 <> ".md"))
    |> Enum.map(&Path.join(dir, &1))
    |> Enum.each(&File.touch!/1)
  end
end
