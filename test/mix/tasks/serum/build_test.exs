defmodule Mix.Tasks.Serum.BuildTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Serum.TestHelper
  alias Mix.Tasks.Serum.Build, as: BuildTask

  setup do
    tmp_dir = get_tmp_dir("serum_test_")
    src = Path.join(tmp_dir, "src")
    cwd = File.cwd!()

    make_project(src)
    File.cd!(src)

    on_exit(fn ->
      File.rm_rf!(tmp_dir)
      File.cd!(cwd)
    end)

    {:ok, src: src}
  end

  describe "mix serum.build" do
    test "builds a valid Serum project" do
      output = capture_io(fn -> BuildTask.run([]) end)

      assert output =~ ~r/Your website is now ready!/
    end

    test "raises an error on build failure", ctx do
      capture_io(fn ->
        ctx.src |> Path.join("serum.exs") |> File.rm_rf!()
        assert_raise Mix.Error, fn -> BuildTask.run([]) end
      end)
    end
  end
end
