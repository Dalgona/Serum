defmodule Serum.Build.FileEmitterTest do
  use Serum.Case, async: true
  alias Serum.Build.FileEmitter
  alias Serum.V2

  setup do
    tmp_dir = get_tmp_dir("serum_test_")

    File.mkdir_p!(tmp_dir)

    files =
      [
        "file1",
        "dir1/file2",
        "dir1/dir1_1/file3",
        "dir1/dir1_2/file4",
        "dir2/dir2_1/file5",
        "dir2/dir2_2/file6",
        "dir2/dir2_2/file7"
      ]
      |> Enum.map(&Path.join(tmp_dir, &1))
      |> Enum.map(&%V2.File{dest: &1, out_data: "Hello, world!\n"})

    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    {:ok, [tmp_dir: tmp_dir, files: files]}
  end

  describe "run/1" do
    test "successfully writes given files to disk", ctx do
      {:ok, _} = FileEmitter.run(ctx.files)

      entry_count =
        ctx.tmp_dir
        |> Path.join("/**")
        |> Path.wildcard()

      assert length(entry_count) === 13
    end

    test "returns an error when fails to create directories", ctx do
      File.chmod!(ctx.tmp_dir, 0o500)

      assert {:error, _} = FileEmitter.run(ctx.files)

      File.chmod!(ctx.tmp_dir, 0o755)
    end

    test "returns an error when fails to write files", ctx do
      path = Path.join(ctx.tmp_dir, "file1")
      :ok = File.touch(path)
      :ok = File.chmod(path, 0o400)

      assert {:error, _} = FileEmitter.run(ctx.files)
    end
  end
end
