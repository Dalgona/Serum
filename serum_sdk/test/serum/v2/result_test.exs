defmodule Serum.V2.ResultTest do
  use ExUnit.Case, async: true
  require Serum.V2.Result, as: Result
  alias Serum.V2
  alias Serum.V2.Error
  alias Serum.V2.Error.{ExceptionMessage, POSIXMessage, SimpleMessage}

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
      error = Result.fail("test error")
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
    test "creates a valid result value" do
      assert {:error, %Error{} = error} = Result.fail("oh, no!")
      assert error.message === %SimpleMessage{text: "oh, no!"}
    end
  end

  describe "fail/2, as fail/1 with options" do
    test "creates a valid result value" do
      file = %V2.File{src: "nofile"}

      assert {:error, %Error{} = error} = Result.fail("oh, no!", file: file, line: 3)
      assert error.message === %SimpleMessage{text: "oh, no!"}
      assert error.file === file
      assert error.line === 3
    end
  end

  describe "fail/2, as fail/3 without options" do
    test "creates a valid result value" do
      assert {:error, %Error{} = error} = Result.fail(POSIX, :enoent)
      assert error.message === %POSIXMessage{reason: :enoent}
    end
  end

  describe "fail/3" do
    test "creates a valid result value" do
      file = %V2.File{src: "nofile"}

      assert {:error, %Error{} = error} = Result.fail(Simple, "oh, no!", file: file, line: 3)
      assert error.message === %SimpleMessage{text: "oh, no!"}
      assert error.file === file
      assert error.line === 3
    end
  end

  describe "from_exception/1" do
    test "expands into a valid expression" do
      ast =
        quote do
          try do
            raise "oh, no!"
          rescue
            e -> Result.from_exception(e)
          end
        end

      {expr, _bindings} = Code.eval_quoted(ast, [], __ENV__)

      assert {:error, %Error{} = error} = expr

      assert %ExceptionMessage{
               exception: %RuntimeError{},
               stacktrace: [_ | _]
             } = error.message
    end
  end

  describe "from_exception/2" do
    test "expands into a valid expression" do
      file = %V2.File{src: "nofile"}

      ast =
        quote do
          try do
            raise "oh, no!"
          rescue
            e -> Result.from_exception(e, file: unquote(Macro.escape(file)), line: 3)
          end
        end

      {expr, _bindings} = Code.eval_quoted(ast, [], __ENV__)

      assert {:error, %Error{} = error} = expr

      assert %ExceptionMessage{
               exception: %RuntimeError{},
               stacktrace: [_ | _]
             } = error.message

      assert error.file === file
      assert error.line === 3
    end
  end
end
