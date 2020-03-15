defmodule Serum.ResultTest do
  use ExUnit.Case, async: true
  require Serum.Result, as: Result
  alias Serum.Error
  alias Serum.Error.SimpleMessage

  describe "get_message/2" do
    test "gets a message for {:ok, result}" do
      assert Result.get_message({:ok, 42}, 0) =~ "No error detected"
    end

    test "gets a message for {:ok, %Error{}}" do
      result = {:error, %Error{message: %SimpleMessage{text: "test error"}, caused_by: []}}

      assert Result.get_message(result, 0) =~ "test error"
    end
  end
end
