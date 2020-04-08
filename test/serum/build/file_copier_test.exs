defmodule Serum.Build.FileCopierTest do
  use Serum.Case
  require Serum.TestHelper
  alias Serum.Build.FileCopier, as: FC
  alias Serum.Result
  alias Serum.Theme

  [
    "theme_modules/dummy_theme.ex",
    "theme_modules/empty_theme.ex",
    "theme_modules/failing_theme.ex"
  ]
  |> Enum.map(&fixture/1)
  |> Enum.each(&Code.require_file/1)

  setup do
    src = get_tmp_dir("serum_test_")
    dest = get_tmp_dir("serum_test_")

    File.mkdir_p!(src)
    File.mkdir_p!(dest)

    on_exit(fn ->
      File.rm_rf!(src)
      File.rm_rf!(dest)
    end)

    {:ok, %{src: src, dest: dest}}
  end

  describe "copy_files/2 without a theme" do
    setup do
      Theme.load(nil)

      :ok
    end

    test "copies assets, media, and extra files", %{src: src, dest: dest} do
      make_structure!(src)

      {:ok, _} = FC.copy_files(src, dest)

      assert num_of_items(dest) === 5
    end

    test "skips copying if sources don't exist", %{src: src, dest: dest} do
      {:ok, _} = FC.copy_files(src, dest)

      assert File.ls!(dest) === []
    end
  end

  describe "copy_files/2 with a theme" do
    test "copies assets from the theme", %{src: src, dest: dest} do
      tmp_dir = get_tmp_dir("serum_test_")
      {:ok, _} = Agent.start_link(fn -> tmp_dir end, name: Serum.TestAgent)

      File.mkdir_p!(tmp_dir)
      File.touch!(Path.join(tmp_dir, "theme_asset"))
      Theme.load(Serum.DummyTheme)
      make_structure!(src)

      {:ok, _} = FC.copy_files(src, dest)

      assert num_of_items(dest) === 6

      :ok = Agent.stop(Serum.TestAgent)
    end

    test "can skip copying assets from the theme", %{src: src, dest: dest} do
      Theme.load(Serum.EmptyTheme)
      make_structure!(src)

      {:ok, _} = FC.copy_files(src, dest)

      assert num_of_items(dest) === 5
    end

    test "fails on theme failure", %{src: src, dest: dest} do
      Theme.load(Serum.FailingTheme)

      result = FC.copy_files(src, dest)

      assert {:error, _} = result
      assert Result.get_message(result, 0) =~ "test error"
    end
  end

  @spec make_structure!(binary()) :: :ok
  defp make_structure!(src) do
    Enum.each(~w(assets files media), fn subdir ->
      dir = Path.join(src, subdir)

      File.mkdir_p!(dir)
      File.touch!(Path.join(dir, "file"))
    end)
  end

  @spec num_of_items(binary()) :: pos_integer()
  defp num_of_items(path) do
    path
    |> Path.join("**/*")
    |> Path.wildcard()
    |> length()
  end
end
