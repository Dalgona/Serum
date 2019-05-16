defmodule Serum.BuildTest do
  use ExUnit.Case
  require Serum.TestHelper
  import Serum.TestHelper, only: :macros
  alias Serum.Build
  alias Serum.Project.Loader, as: ProjectLoader

  setup do
    uniq = Base.url_encode64(:crypto.strong_rand_bytes(6))
    tmp_dir = Path.expand("serum_test_" <> uniq, System.tmp_dir!())
    src = Path.join(tmp_dir, "src")
    dest = Path.join(tmp_dir, "dest")

    Enum.each([tmp_dir, src, dest], &File.mkdir_p!/1)

    ~w(pages posts includes templates assets media)
    |> Enum.map(&Path.join(src, &1))
    |> Enum.each(&File.mkdir_p!/1)

    File.touch!(Path.join([src, "assets", "test_asset"]))
    File.touch!(Path.join([src, "media", "test_media"]))

    File.cp!(fixture("proj/good/serum.exs"), Path.join(src, "serum.exs"))
    File.cp!(fixture("templates/nav.html.eex"), Path.join(src, "includes/nav.html.eex"))
    {:ok, proj} = ProjectLoader.load(src, dest)

    [
      "base.html.eex",
      "page.html.eex",
      "post.html.eex",
      "list.html.eex"
    ]
    |> Enum.each(fn file ->
      File.cp!(Path.join(fixture("templates"), file), Path.join([src, "templates", file]))
    end)

    "pages/good-*.md"
    |> fixture()
    |> Path.wildcard()
    |> Enum.each(fn file ->
      File.cp!(file, Path.join([src, "pages", Path.basename(file)]))
    end)

    "posts/good-*.md"
    |> fixture()
    |> Path.wildcard()
    |> Enum.each(fn file ->
      File.cp!(file, Path.join([src, "posts", Path.basename(file)]))
    end)

    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    {:ok, [src: src, dest: dest, proj: proj]}
  end

  test "everything went well", %{dest: dest, proj: proj} do
    assert {:ok, ^dest} = mute_stdio(do: Build.build(proj))

    # Clean the destination dir when is not empty
    assert {:ok, ^dest} = mute_stdio(do: Build.build(proj))
  end

  test "skip copying assets and media", %{src: src, dest: dest, proj: proj} do
    File.rm_rf!(Path.join(src, "assets"))
    File.rm_rf!(Path.join(src, "media"))

    assert {:ok, ^dest} = mute_stdio(do: Build.build(proj))
  end

  test "no write permission on dest", %{dest: dest, proj: proj} do
    File.chmod!(dest, 0o555)

    assert {:error, _} = mute_stdio(do: Build.build(proj))

    File.chmod!(dest, 0o755)
    File.rm_rf!(dest)

    parent = Path.expand(Path.join(dest, ".."))

    File.chmod!(parent, 0o555)

    assert {:error, _} = mute_stdio(do: Build.build(proj))

    File.chmod!(parent, 0o755)
  end

  test "failed to load required files", %{src: src, proj: proj} do
    File.rm_rf!(Path.join(src, "templates"))

    assert {:error, _} = mute_stdio(do: Build.build(proj))
  end

  test "failed to process some files", %{src: src, proj: proj} do
    "pages/bad-*.*"
    |> fixture()
    |> Path.wildcard()
    |> Enum.each(fn file ->
      File.cp!(file, Path.join([src, "pages", Path.basename(file)]))
    end)

    assert {:error, _} = mute_stdio(do: Build.build(proj))
  end
end
