defmodule Serum.ErrorTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  import Serum.Error

  describe "filter_results/2" do
    test "all ok" do
      assert :ok == filter_results([:ok, :ok], :whatever)
    end

    test "has errors" do
      assert {:error, :child_tasks, {:whatever, [:not_ok, :wtf]}} ==
        filter_results([:ok, :ok, :not_ok, :wtf], :whatever)
    end
  end

  describe "show/2" do
    test "when ok" do
      assert "No errors detected.\n" == capture_io(fn -> show(:ok) end)
      assert "  No errors detected.\n" == capture_io(fn -> show(:ok, 1) end)
      assert "No errors detected.\n" == capture_io(fn -> show({:ok, 1}) end)
      assert "  No errors detected.\n" == capture_io(fn -> show({:ok, 1}, 1) end)
    end

    test "when error with reason" do
      assert "\e[31m❌\e[0m  User error\n" ==
        capture_io(fn -> show({:error, "User error", nil}) end)
      assert "  \e[31m❌\e[0m  User error\n" ==
        capture_io(fn -> show({:error, "User error", nil}, 1) end)
    end

    test "when error with message" do
      assert "\e[31m❌\e[0m  Oh no\n" ==
        capture_io(fn -> show({:error, "User error", "Oh no"}) end)
      assert "  \e[31m❌\e[0m  Oh no\n" ==
        capture_io(fn -> show({:error, "User error", "Oh no"}, 1) end)
    end

    test "when error with message in file" do
      assert "\e[31m❌\e[0m  \x1b[97ma.md:\x1b[0m Oh no\n" ==
        capture_io(fn -> show({:error, :a, {"Oh no", "a.md", 0}}) end)
      assert "  \e[31m❌\e[0m  \x1b[97ma.md:\x1b[0m Oh no\n" ==
        capture_io(fn -> show({:error, :a, {"Oh no", "a.md", 0}}, 1) end)
    end

    test "when error with message in file line" do
      assert "\e[31m❌\e[0m  \x1b[97ma.md:1:\x1b[0m Oh no\n" ==
        capture_io(fn -> show({:error, :a, {"Oh no", "a.md", 1}}) end)
      assert "  \e[31m❌\e[0m  \x1b[97ma.md:1:\x1b[0m Oh no\n" ==
        capture_io(fn -> show({:error, :a, {"Oh no", "a.md", 1}}, 1) end)
    end
    test "when errors with in child task" do
      assert "\e[1;31mSeveral errors occurred from 1:\e[0m\n  \e[31m❌\e[0m  no\n  \e[31m❌\e[0m  np\n" ==
        capture_io(fn ->
          show({:error, :child_tasks, {1, [{:error, :no, nil}, {:error, :np, nil}]}})
        end)
      assert "  \e[1;31mSeveral errors occurred from 1:\e[0m\n    \e[31m❌\e[0m  no\n    \e[31m❌\e[0m  np\n" ==
        capture_io(fn ->
          show({:error, :child_tasks, {1, [{:error, :no, nil}, {:error, :np, nil}]}}, 1)
        end)
    end
  end
end
