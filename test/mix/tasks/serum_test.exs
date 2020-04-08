defmodule Mix.Tasks.SerumTest do
  use Serum.Case
  import ExUnit.CaptureIO
  alias Mix.Tasks.Serum, as: SerumTask

  describe "mix serum" do
    test "prints a list of available tasks" do
      output = capture_io(fn -> SerumTask.run([]) end)

      ~w(serum serum.build serum.server serum.gen.page serum.gen.post)
      |> Enum.each(fn task_name ->
        assert output =~ task_name
      end)
    end

    test "controls colored output with --(no-)color option" do
      output = capture_io(fn -> SerumTask.run(["--color"]) end)

      assert output =~ ~r/\x1b\[[^m]+m/

      output = capture_io(fn -> SerumTask.run(["--no-color"]) end)

      assert not (output =~ ~r/\x1b\[[^m]+m/)
    end
  end
end
