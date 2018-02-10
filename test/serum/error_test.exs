defmodule ErrorTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  import Serum.Error

  @bullet "\x1b[31m\u274c\x1b[0m "

  defp errobj, do: {:error, "test"}
  defp errobj(x), do: {:error, "test #{x}"}

  describe "filter_results" do
    test "an empty list" do
      assert :ok == filter_results([], :test)
    end

    test "one :ok" do
      assert :ok == filter_results([:ok], :test)
    end

    test "multiple :ok" do
      assert :ok == filter_results([:ok, :ok, :ok], :test)
    end

    test "one error" do
      expected = {:error, {:test, [errobj()]}}
      assert expected == filter_results([:ok, errobj(), :ok], :test)
    end

    test "several errors" do
      expected = {:error, {:test, [errobj(1), errobj(2)]}}
      assert expected == filter_results([errobj(1), :ok, errobj(2), :ok], :test)
    end
  end

  describe "filter_results_with_values" do
    test "an empty list" do
      assert {:ok, []} == filter_results_with_values([], :test)
    end

    test "one result" do
      assert {:ok, [42]} == filter_results_with_values([ok: 42], :test)
    end

    test "multiple results" do
      assert {:ok, [1, 2]} == filter_results_with_values([ok: 1, ok: 2], :test)
    end

    test "one error" do
      expected = {:error, {:test, [errobj()]}}
      assert expected == filter_results_with_values([{:ok, 42}, errobj()], :test)
    end

    test "several errors" do
      expected = {:error, {:test, [errobj(1), errobj(2)]}}
      data = [errobj(1), {:ok, 42}, errobj(2), {:ok, 84}]
      assert expected == filter_results(data, :test)
    end
  end

  describe "show :ok" do
    test "without indent" do
      output = capture_io(fn -> show(:ok) end)
      assert "No errors detected.\n" == output
    end

    test "with indent" do
      output = capture_io(fn -> show(:ok, 2) end)
      assert "    No errors detected.\n" == output
    end
  end

  describe "show {:ok, res}" do
    test "without indent" do
      output = capture_io(fn -> show({:ok, "lorem"}) end)
      assert "No errors detected.\n" == output
    end

    test "with indent" do
      output = capture_io(fn -> show({:ok, "ipsum"}, 2) end)
      assert "    No errors detected.\n" == output
    end
  end

  describe "show msg_detail" do
    test "without indent" do
      output = capture_io(fn -> show({:error, "oh no"}) end)
      assert "#{@bullet} oh no\n" == output
    end

    test "with indent" do
      output = capture_io(fn -> show({:error, "oh no"}, 2) end)
      assert "    #{@bullet} oh no\n" == output
    end
  end

  describe "show full_detail w/ line" do
    test "without indent" do
      output = capture_io(fn -> show({:error, {"nope", "foo", 3}}) end)
      assert "#{@bullet} \x1b[97mfoo:3:\x1b[0m nope\n" == output
    end

    test "with indent" do
      output = capture_io(fn -> show({:error, {"nope", "foo", 3}}, 2) end)
      assert "    #{@bullet} \x1b[97mfoo:3:\x1b[0m nope\n" == output
    end
  end

  describe "show file_error" do
    test "enoent without indent" do
      output =
        capture_io(fn ->
          show({:error, {:enoent, "testfile", 0}})
        end)

      expected = "#{@bullet} \x1b[97mtestfile:\x1b[0m no such file or directory\n"
      assert expected == output
    end

    test "eacces with indent" do
      output =
        capture_io(fn ->
          show({:error, {:eacces, "testfile", 0}}, 2)
        end)

      expected = "    #{@bullet} \x1b[97mtestfile:\x1b[0m permission denied\n"
      assert expected == output
    end
  end

  describe "show nested errors" do
    test "1 level without indent" do
      output =
        capture_io(fn ->
          show({:error, {:foo, [{:error, "oh no!"}, {:error, {"oh no!", "foo", 0}}]}})
        end)

      expected = """
      \x1b[1;31mSeveral errors occurred from foo:\x1b[0m
        #{@bullet} oh no!
        #{@bullet} \x1b[97mfoo:\x1b[0m oh no!
      """

      assert expected == output
    end

    test "1 level with indent" do
      output =
        capture_io(fn ->
          show({:error, {:foo, [{:error, "oh no!"}, {:error, {"oh no!", "foo", 0}}]}}, 2)
        end)

      expected = """
          \x1b[1;31mSeveral errors occurred from foo:\x1b[0m
            #{@bullet} oh no!
            #{@bullet} \x1b[97mfoo:\x1b[0m oh no!
      """

      assert expected == output
    end

    test "2 level without indent" do
      output =
        capture_io(fn ->
          show(
            {:error,
             {:foo, [{:error, {:bar, [{:error, "oh no!"}, {:error, {"oh no!", "foo", 0}}]}}]}}
          )
        end)

      expected = """
      \x1b[1;31mSeveral errors occurred from foo:\x1b[0m
        \x1b[1;31mSeveral errors occurred from bar:\x1b[0m
          #{@bullet} oh no!
          #{@bullet} \x1b[97mfoo:\x1b[0m oh no!
      """

      assert expected == output
    end

    test "2 level with indent" do
      output =
        capture_io(fn ->
          show(
            {:error,
             {:foo, [{:error, {:bar, [{:error, "oh no!"}, {:error, {"oh no!", "foo", 0}}]}}]}},
            2
          )
        end)

      expected = """
          \x1b[1;31mSeveral errors occurred from foo:\x1b[0m
            \x1b[1;31mSeveral errors occurred from bar:\x1b[0m
              #{@bullet} oh no!
              #{@bullet} \x1b[97mfoo:\x1b[0m oh no!
      """

      assert expected == output
    end
  end
end
