defmodule Serum.Build.FileCopierTest do
  use Serum.Case
  require Serum.TestHelper
  alias Serum.Build.FileCopier, as: FC
  alias Serum.Theme
  alias Serum.Theme.Loader, as: ThemeLoader
  alias Serum.V2.Error

  setup do
    src = get_tmp_dir("serum_test_")
    dest = get_tmp_dir("serum_test_")

    File.mkdir_p!(src)
    File.mkdir_p!(dest)

    on_exit(fn ->
      File.rm_rf!(src)
      File.rm_rf!(dest)
      ThemeLoader.load_theme(nil)
    end)

    {:ok, %{src: src, dest: dest}}
  end

  describe "copy_files/2 without a theme" do
    setup do
      ThemeLoader.load_theme(nil)

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
      theme_mock = get_theme_mock(%{get_assets: fn _ -> {:ok, tmp_dir} end})

      File.mkdir_p!(tmp_dir)
      File.touch!(Path.join(tmp_dir, "theme_asset"))

      {:ok, %Theme{}} = ThemeLoader.load_theme(theme_mock)

      make_structure!(src)

      assert {:ok, _} = FC.copy_files(src, dest)
      assert num_of_items(dest) === 6

      File.rm_rf!(tmp_dir)
    end

    test "can skip copying assets from the theme", %{src: src, dest: dest} do
      theme_mock = get_theme_mock(%{get_themes: fn _ -> {:ok, false} end})
      {:ok, %Theme{}} = ThemeLoader.load_theme(theme_mock)

      make_structure!(src)

      {:ok, _} = FC.copy_files(src, dest)

      assert num_of_items(dest) === 5
    end

    test "fails on theme failure", %{src: src, dest: dest} do
      theme_mock = get_theme_mock(%{get_assets: fn _ -> raise "test: get_assets" end})
      {:ok, %Theme{}} = ThemeLoader.load_theme(theme_mock)

      assert {:error, %Error{} = error} = FC.copy_files(src, dest)
      assert to_string(error) =~ "test: get_assets"
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
