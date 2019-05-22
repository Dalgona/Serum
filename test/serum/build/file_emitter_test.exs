defmodule Serum.Build.FileEmitterTest do
  use ExUnit.Case, async: true
  import Serum.TestHelper
  alias Serum.Build.FileEmitter

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
      |> Enum.map(&%Serum.File{dest: &1, out_data: "Hello, world!\n"})

    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    {:ok, [tmp_dir: tmp_dir, files: files]}
  end

  describe "run/1" do
    test "successful", ctx do
      :ok = FileEmitter.run(ctx.files)

      entry_count =
        ctx.tmp_dir
        |> Path.join("/**")
        |> Path.wildcard()

      assert length(entry_count) === 13
    end

    test "super rare situation here", ctx do
      File.chmod!(ctx.tmp_dir, 0o500)

      {:error, _} = FileEmitter.run(ctx.files)

      File.chmod!(ctx.tmp_dir, 0o755)
    end
  end
end
