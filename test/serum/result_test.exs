defmodule Serum.ResultTest do
  use ExUnit.Case, async: true
  require Serum.Result, as: Result
  alias Serum.Error
  alias Serum.Error.Format
  alias Serum.Error.SimpleMessage

  describe "aggregate/2" do
    test "processes a list of successful results with value" do
      results = Enum.map(1..5, &{:ok, &1})
      result = Result.aggregate(results, "foo")
      expected = {:ok, [1, 2, 3, 4, 5]}

      assert result === expected
    end

    test "processes a list of successful/failed results" do
      results = [ok: 1, error: "error 1", ok: 2, error: "error 2", ok: 3]
      {:error, error} = Result.aggregate(results, "foo")

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

      {:error, error} = Result.aggregate(results, "foo")

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

  describe "run/1" do
    test "expands to appropriate `with` construct" do
      ast =
        quote do
          Result.run do
            x <- foo()
            y = bar()
            baz()
            spam()
          end
        end

      generated_code = ast |> Macro.expand(__ENV__) |> Macro.to_string()

      assert generated_code =~ ~r/\{:ok, x\} <- foo\(\),/
      assert generated_code =~ ~r/y = bar\(\),/
      assert generated_code =~ ~r/\{:ok, _\} <- baz\(\)/
      assert generated_code =~ ~r/\s*spam\(\)/
      assert generated_code =~ ~r/else\n\s*\{:error, %Serum.Error\{\}\} = error ->\n\s*error/
    end
  end

  describe "run/2" do
    test "modifies else clauses according to the given argument" do
      ast =
        quote do
          Result.run do
            x <- foo()
            y <- bar()
            baz()
          else
            :oh_no -> nil
          end
        end

      generated_code = ast |> Macro.expand(__ENV__) |> Macro.to_string()

      assert generated_code =~ ~r/else\n\s*:oh_no ->\n\s*nil\n\s*end/
    end
  end

  describe "fail/3" do
    test "expands into appropriate error expression" do
      ast =
        quote do
          Result.fail(Simple, ["test error"], file: %Serum.File{src: "nofile"}, line: 3)
        end

      generated_code = ast |> Macro.expand(__ENV__) |> Macro.to_string()

      assert generated_code =~ ~r/^\{:error, %Serum.Error/
      assert generated_code =~ "Serum.Error.SimpleMessage.message([\"test error\"])"
      assert generated_code =~ ~r/file: %Serum.File{[^}]*src: \"nofile\"/
      assert generated_code =~ "caused_by: []"
      assert generated_code =~ "line: 3"
    end

    test "expands into appropriate error expression, with default opts" do
      ast = quote(do: Result.fail(Simple, ["test error"]))
      generated_code = ast |> Macro.expand(__ENV__) |> Macro.to_string()

      assert generated_code =~ "caused_by: []"
      assert generated_code =~ "file: nil"
      assert generated_code =~ "line: nil"
    end
  end
end
