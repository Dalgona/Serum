defmodule Serum.ResultTest do
  use ExUnit.Case, async: true
  alias Serum.Error
  alias Serum.Error.Format
  alias Serum.Error.SimpleMessage
  alias Serum.Result

  describe "aggregate_values/2" do
    test "processes a list of successful results with value" do
      results = Enum.map(1..5, &{:ok, &1})
      result = Result.aggregate_values(results, "foo")
      expected = {:ok, [1, 2, 3, 4, 5]}

      assert result === expected
    end

    test "processes a list of successful/failed results" do
      results = [ok: 1, error: "error 1", ok: 2, error: "error 2", ok: 3]
      {:error, error} = Result.aggregate_values(results, "foo")

      message =
        error.message
        |> Format.format_text(0)
        |> IO.ANSI.format()
        |> IO.iodata_to_binary()

      assert message === "foo"
      assert length(error.caused_by) === 2
    end

    test "removes duplicate failed results #1" do
      results = [
        error: "error 1",
        error: "error 2",
        error: "error 1",
        error: "error 2"
      ]

      {:error, error} = Result.aggregate_values(results, "foo")

      assert length(error.caused_by) === 2
    end
  end

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
