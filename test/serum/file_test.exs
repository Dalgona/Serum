defmodule Serum.FileTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  import Serum.TestHelper

  @content1 "The quick brown fox jumps over the lazy dog.\n"

  setup_all do
    tmp_dir = get_tmp_dir("serum_test_")

    File.mkdir_p!(tmp_dir)

    File.open!(Path.join(tmp_dir, "file1"), [:write, :utf8], fn pid ->
      IO.write(pid, @content1)
    end)

    on_exit(fn ->
      File.rm_rf!(tmp_dir)
    end)

    [tmp_dir: tmp_dir]
  end

  describe "read/1" do
    test "successfully read a file", context do
      file = %Serum.File{
        src: Path.join(context.tmp_dir, "file1"),
        dest: nil,
        in_data: nil,
        out_data: nil
      }

      {:ok, %Serum.File{} = read_file} = Serum.File.read(file)

      assert read_file.in_data === @content1
    end

    test "try to read a file that does not exist", context do
      file = %Serum.File{
        src: Path.join(context.tmp_dir, "asdfasdf"),
        dest: nil,
        in_data: nil,
        out_data: nil
      }

      src = file.src

      assert {:error, {:enoent, ^src, 0}} = Serum.File.read(file)
    end
  end

  describe "write/1" do
    test "successfully write a file", context do
      file = %Serum.File{
        src: nil,
        dest: Path.join(context.tmp_dir, "file2"),
        in_data: nil,
        out_data: "Lorem ipsum dolor sit amet\n"
      }

      capture_io(fn ->
        assert {:ok, ^file} = Serum.File.write(file)
      end)

      assert file.out_data === File.read!(Path.join(context.tmp_dir, "file2"))
    end

    test "write a file in a directory without a write permission", context do
      tmp_dir2 = Path.join(context.tmp_dir, "test")

      File.mkdir_p!(tmp_dir2)
      File.chmod!(tmp_dir2, 0o555)

      file = %Serum.File{
        src: nil,
        dest: Path.join(tmp_dir2, "file3"),
        in_data: nil,
        out_data: "Lorem ipsum dolor sit amet\n"
      }

      dest = file.dest

      assert {:error, {:eacces, ^dest, 0}} = Serum.File.write(file)
    end
  end
end
