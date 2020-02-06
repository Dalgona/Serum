defmodule Serum.V2.FileTest do
  use ExUnit.Case
  alias Serum.V2
  alias Serum.V2.Error

  setup_all do
    uniq = Base.url_encode64(:crypto.strong_rand_bytes(6))
    tmp_dir = Path.expand("serum_test_" <> uniq, System.tmp_dir!())

    File.mkdir_p!(tmp_dir)

    File.open!(Path.join(tmp_dir, "file"), [:write, :utf8], fn device ->
      IO.puts(device, "Hello, world!")
    end)

    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    {:ok, tmp_dir: tmp_dir}
  end

  describe "read/1" do
    test "reads a valid file from disk", %{tmp_dir: dir} do
      file = %V2.File{
        src: Path.join(dir, "file"),
        in_data: nil
      }

      assert {:ok, %V2.File{} = read_file} = V2.File.read(file)
      assert read_file.in_data === "Hello, world!\n"
    end

    test "returns an error when failed to read the file", %{tmp_dir: dir} do
      file_path = Path.join(dir, "file")
      file = %V2.File{src: file_path, in_data: nil}

      File.chmod!(file_path, 0o000)

      assert {:error, %Error{} = error} = V2.File.read(file)
      assert error.message.reason === :eacces

      File.chmod!(file_path, 0o644)
    end

    test "returns an error when `src` is nil" do
      assert {:error, %Error{}} = V2.File.read(%V2.File{})
    end
  end

  describe "write/1" do
    test "writes a file to disk", %{tmp_dir: dir} do
      file_path = Path.join(dir, "file2")
      file = %V2.File{dest: file_path, out_data: "Lorem ipsum\n"}

      assert {:ok, ^file} = V2.File.write(file)
      assert File.exists?(file_path)
    end

    test "returns an error when failed to write the file", %{tmp_dir: dir} do
      File.chmod!(dir, 0o400)

      file_path = Path.join(dir, "file2")
      file = %V2.File{dest: file_path, out_data: "Lorem ipsum\n"}

      assert {:error, %Error{} = error} = V2.File.write(file)
      assert error.message.reason === :eacces
      refute File.exists?(file_path)

      File.chmod!(dir, 0o755)
    end

    test "returns an error when `dest` is nil" do
      assert {:error, %Error{}} = V2.File.write(%V2.File{})
    end
  end
end
