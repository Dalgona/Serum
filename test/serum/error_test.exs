defmodule ErrorTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  import Serum.Error

  @bullet "\x1b[31m\u274c\x1b[0m "

  describe "show :ok" do
    test "without indent" do
      output = capture_io fn -> show :ok end
      assert "No errors detected.\n" == output
    end

    test "with indent" do
      output = capture_io fn -> show :ok, 2 end
      assert "    No errors detected.\n" == output
    end
  end

  describe "show {:ok, res}" do
    test "without indent" do
      output = capture_io fn -> show {:ok, "lorem"} end
      assert "No errors detected.\n" == output
    end

    test "with indent" do
      output = capture_io fn -> show {:ok, "ipsum"}, 2 end
      assert "    No errors detected.\n" == output
    end
  end

  describe "show no_detail" do
    test "without indent" do
      output = capture_io fn -> show {:error, :test_error, nil} end
      assert "#{@bullet} test_error\n" == output
    end

    test "with indent" do
      output = capture_io fn -> show {:error, :test_error, nil}, 2 end
      assert "    #{@bullet} test_error\n" == output
    end
  end

  describe "show msg_detail" do
    test "without indent" do
      output = capture_io fn -> show {:error, :test_error, "oh no"} end
      assert "#{@bullet} oh no\n" == output
    end

    test "with indent" do
      output = capture_io fn -> show {:error, :test_error, "oh no"}, 2 end
      assert "    #{@bullet} oh no\n" == output
    end
  end

  describe "show full_detail w/ line" do
    test "without indent" do
      output = capture_io fn -> show {:error, :boo, {"nope", "foo", 3}} end
      assert "#{@bullet} \x1b[97mfoo:3:\x1b[0m nope\n" == output
    end

    test "with indent" do
      output = capture_io fn -> show {:error, :boo, {"nope", "foo", 3}}, 2 end
      assert "    #{@bullet} \x1b[97mfoo:3:\x1b[0m nope\n" == output
    end
  end

  describe "show file_error" do
    test "enoent without indent" do
      output =
        capture_io fn ->
          show {:error, :file_error, {:enoent, "testfile", 0}}
        end
      expected
        = "#{@bullet} \x1b[97mtestfile:\x1b[0m no such file or directory\n"
      assert expected == output
    end

    test "eacces with indent" do
      output =
        capture_io fn ->
          show {:error, :file_error, {:eacces, "testfile", 0}}, 2
        end
      expected
        = "    #{@bullet} \x1b[97mtestfile:\x1b[0m permission denied\n"
      assert expected == output
    end
  end

  describe "show nested errors" do
    test "1 level without indent" do
      output =
        capture_io fn ->
          show {:error, :child_tasks,
                {:foo,
                 [{:error, :boo, nil},
                  {:error, :some_error, "oh no!"},
                  {:error, :yuck, {"oh no!", "foo", 0}}]}}
        end
      expected =
        """
        \x1b[1;31mSeveral errors occurred from foo:\x1b[0m
          #{@bullet} boo
          #{@bullet} oh no!
          #{@bullet} \x1b[97mfoo:\x1b[0m oh no!
        """
      assert expected == output
    end

    test "1 level with indent" do
      output =
        capture_io fn ->
          show {:error, :child_tasks,
                {:foo,
                 [{:error, :boo, nil},
                  {:error, :some_error, "oh no!"},
                  {:error, :yuck, {"oh no!", "foo", 0}}]}}, 2
        end
      expected =
        """
            \x1b[1;31mSeveral errors occurred from foo:\x1b[0m
              #{@bullet} boo
              #{@bullet} oh no!
              #{@bullet} \x1b[97mfoo:\x1b[0m oh no!
        """
      assert expected == output
    end

    test "2 level without indent" do
      output =
        capture_io fn ->
          show {:error, :child_tasks,
                {:foo,
                 [{:error, :child_tasks,
                   {:bar,
                    [{:error, :boo, nil},
                     {:error, :some_error, "oh no!"},
                     {:error, :yuck, {"oh no!", "foo", 0}}]}}]}}
        end
      expected =
        """
        \x1b[1;31mSeveral errors occurred from foo:\x1b[0m
          \x1b[1;31mSeveral errors occurred from bar:\x1b[0m
            #{@bullet} boo
            #{@bullet} oh no!
            #{@bullet} \x1b[97mfoo:\x1b[0m oh no!
        """
      assert expected == output
    end

    test "2 level with indent" do
      output =
        capture_io fn ->
          show {:error, :child_tasks,
                {:foo,
                 [{:error, :child_tasks,
                   {:bar,
                    [{:error, :boo, nil},
                     {:error, :some_error, "oh no!"},
                     {:error, :yuck, {"oh no!", "foo", 0}}]}}]}}, 2
        end
      expected =
        """
            \x1b[1;31mSeveral errors occurred from foo:\x1b[0m
              \x1b[1;31mSeveral errors occurred from bar:\x1b[0m
                #{@bullet} boo
                #{@bullet} oh no!
                #{@bullet} \x1b[97mfoo:\x1b[0m oh no!
        """
      assert expected == output
    end
  end
end
