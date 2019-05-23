defmodule Serum.ResultTest do
  use ExUnit.Case, async: true
  alias Serum.Result

  describe "get_message/2" do
    test "gets a message for :ok" do
      assert Result.get_message(:ok, 0) =~ "No error detected"
    end

    test "gets a message for {:ok, result}" do
      assert Result.get_message({:ok, 42}, 0) =~ "No error detected"
    end

    test "gets a message for {:error, msg}" do
      assert Result.get_message({:error, "test message"}, 0) =~ "test message"
    end

    test "gets a message for {:error, {msg, file, 0}}" do
      error = {:error, {"test message", "test_file", 0}}
      message = Result.get_message(error, 0)

      assert message =~ "test_file: test message"
    end

    test "gets a message for {:error, {msg, file, line}}" do
      error = {:error, {"test message", "test_file", 10}}
      message = Result.get_message(error, 0)

      assert message =~ "test_file:10: test message"
    end

    test "gets a message for {:error, {posix, file, line}}" do
      message = Result.get_message({:error, {:enoent, "test_file", 0}}, 0)
      enoent = :enoent |> :file.format_error() |> IO.iodata_to_binary()

      assert message =~ "test_file: #{enoent}"
    end

    test "gets a message for {:error, {msg, errors}}" do
      errors = [{:error, "foo"}, {:error, "bar"}]
      error = {:error, {"test errors", errors}}
      [l1, l2, l3] = error |> Result.get_message(0) |> String.split(~r/\r?\n/)

      assert l1 =~ "test errors"
      assert l2 =~ "foo"
      assert l3 =~ "bar"
    end
  end
end
