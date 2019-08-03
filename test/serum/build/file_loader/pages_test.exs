defmodule Serum.Build.FileLoader.PagesTest do
  use ExUnit.Case
  import Serum.Build.FileLoader.Pages
  import Serum.TestHelper
  alias Serum.Plugin

  "plugins/failing_plugin_1.ex"
  |> fixture()
  |> Code.require_file()

  describe "load/1" do
    setup do
      tmp_dir = get_tmp_dir("serum_test_")

      File.mkdir_p!(tmp_dir)

      on_exit(fn ->
        File.rm_rf!(tmp_dir)
        Plugin.load_plugins([])
      end)

      {:ok, tmp_dir: tmp_dir}
    end

    test "loads page files", %{tmp_dir: tmp_dir} do
      pages_dir = Path.join(tmp_dir, "pages")

      make_files(pages_dir)

      assert {:ok, files} = load(tmp_dir)
      assert 3 === length(files)
    end

    test "fails if the pages directory does not exist", %{tmp_dir: tmp_dir} do
      assert {:error, _} = load(tmp_dir)
    end

    test "fails when some files cannot be loaded", %{tmp_dir: tmp_dir} do
      pages_dir = Path.join(tmp_dir, "pages")
      foo = Path.join(pages_dir, "foo.md")

      make_files(pages_dir)
      File.chmod!(foo, 0o000)

      assert {:error, _} = load(tmp_dir)

      File.chmod!(foo, 0o644)
    end

    test "fails when the loaded plugin fails", %{tmp_dir: tmp_dir} do
      pages_dir = Path.join(tmp_dir, "pages")

      make_files(pages_dir)

      {:ok, _} = Plugin.load_plugins([Serum.FailingPlugin1])

      assert {:error, _} = load(tmp_dir)
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
