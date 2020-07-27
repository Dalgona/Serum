defmodule Serum.BuildTest do
  use Serum.Case
  require Serum.TestHelper
  alias Serum.Build
  alias Serum.Project.Loader, as: ProjectLoader

  setup do
    tmp_dir = get_tmp_dir("serum_test_")
    src = Path.join(tmp_dir, "src")
    dest = Path.join(tmp_dir, "dest")

    Enum.each([tmp_dir, src, dest], &File.mkdir_p!/1)
    make_project(src)

    {:ok, proj} = ProjectLoader.load(src, dest)

    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    {:ok, [src: src, dest: dest, proj: proj]}
  end

  test "builds a valid Serum project", %{src: src, dest: dest, proj: proj} do
    assert {:ok, ^dest} = Build.build(proj, src, dest)

    # Clean the destination dir when is not empty
    assert {:ok, ^dest} = Build.build(proj, src, dest)

    ~w(assets media posts test_file.txt)
    |> Enum.each(fn x ->
      assert x |> Path.expand(dest) |> File.exists?()
    end)
  end

  test "can skip copying assets and media", %{src: src, dest: dest, proj: proj} do
    File.rm_rf!(Path.join(src, "assets"))
    File.rm_rf!(Path.join(src, "media"))

    assert {:ok, ^dest} = Build.build(proj, src, dest)
  end

  test "fails when there is no write permission", %{src: src, dest: dest, proj: proj} do
    File.chmod!(dest, 0o555)

    assert {:error, _} = Build.build(proj, src, dest)

    File.chmod!(dest, 0o755)
    File.rm_rf!(dest)

    parent = Path.expand(Path.join(dest, ".."))

    File.chmod!(parent, 0o555)

    assert {:error, _} = Build.build(proj, src, dest)

    File.chmod!(parent, 0o755)
  end

  test "fails when the output directory cannot be accessed", %{src: src, dest: dest, proj: proj} do
    fake_dest = Path.join([dest, "foo", "bar", "baz"])

    assert {:error, _} = Build.build(proj, src, fake_dest)
  end

  test "aborts when failed to load required files", %{src: src, dest: dest, proj: proj} do
    File.rm_rf!(Path.join(src, "templates"))

    assert {:error, _} = Build.build(proj, src, dest)
  end

  test "aborts when failed to process some files", %{src: src, dest: dest, proj: proj} do
    "pages/bad-*.*"
    |> fixture()
    |> Path.wildcard()
    |> Enum.each(fn file ->
      File.cp!(file, Path.join([src, "pages", Path.basename(file)]))
    end)

    assert {:error, _} = Build.build(proj, src, dest)
  end
end
