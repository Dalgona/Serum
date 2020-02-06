defmodule Serum.V2.ResultTest do
  use ExUnit.Case, async: true
  require Serum.V2.Result, as: Result
  alias Serum.V2

  describe "aggregate/2" do
    test "aggregates a list of successful results" do
      results = Enum.map(1..5, &{:ok, &1})
      result = Result.aggregate(results, "foo")
      expected = {:ok, [1, 2, 3, 4, 5]}

      assert result === expected
    end

    test "aggregates a list of mixed results" do
      results = [ok: 1, error: Error1, ok: 2, error: Error2, ok: 3]
      {:error, error} = Result.aggregate(results, "foo")

      assert error.message.text === "foo"
      assert length(error.caused_by) === 2
    end

    test "removes duplicate failed results" do
      results = [
        error: Error1,
        error: Error2,
        error: Error1,
        error: Error2
      ]

      {:error, error} = Result.aggregate(results, "foo")

      assert length(error.caused_by) === 2
    end
  end

  describe "bind/2" do
    test "binds a value to a function when successful" do
      double = fn x -> Result.return(x * 2) end

      assert {:ok, 10} === Result.bind(Result.return(5), double)
    end

    test "passes the error through when failed" do
      error = Result.fail(Simple: ["test error"])
      double = fn x -> Result.return(x * 2) end

      assert error === Result.bind(error, double)
    end
  end

  describe "run/1" do
    test "expands to appropriate nested bind expressions" do
      ast =
        quote do
          Result.run do
            x <- foo()
            y = bar()
            baz()
            spam()
          end
        end

      generated_code = Macro.expand(ast, __ENV__)

      expected =
        quote do
          Serum.V2.Result.bind(foo(), fn x ->
            y = bar()
            Serum.V2.Result.bind(baz(), fn _ -> spam() end)
          end)
        end

      assert Macro.to_string(generated_code) === Macro.to_string(expected)
    end
  end

  describe "fail/1" do
    test "expands into appropriate error expression" do
      ast =
        quote do
          Result.fail(Simple: ["test error"], file: %V2.File{src: "nofile"}, line: 3)
        end

      generated_code = ast |> Macro.expand(__ENV__) |> Macro.to_string()

      assert generated_code =~ ~r/^\{:error, %Serum.V2.Error/
      assert generated_code =~ "Serum.V2.Error.SimpleMessage.message([\"test error\"])"
      assert generated_code =~ ~r/file: %V2.File{[^}]*src: \"nofile\"/
      assert generated_code =~ "caused_by: []"
      assert generated_code =~ "line: 3"
    end

    test "expands into appropriate error expression, with default opts" do
      ast = quote(do: Result.fail(Simple: ["test error"]))
      generated_code = ast |> Macro.expand(__ENV__) |> Macro.to_string()

      assert generated_code =~ "caused_by: []"
      assert generated_code =~ "file: nil"
      assert generated_code =~ "line: nil"
    end
  end
end
