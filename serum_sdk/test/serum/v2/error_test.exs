defmodule Serum.V2.ErrorTest do
  use ExUnit.Case, async: true
  require Serum.V2.Result, as: Result
  alias Serum.V2
  alias Serum.V2.Error

  describe "prewalk/2" do
    test "performs pre-order traversal to modify nested errors" do
      errors = [
        Result.fail(Simple: "error 1"),
        Result.fail(Simple: "error 2")
      ]

      {:error, error} = Result.aggregate(errors, "multiple errors occurred")
      file = %V2.File{src: "testfile"}

      new_error =
        Error.prewalk(error, fn %Error{} = error ->
          %Error{error | file: file, line: 42}
        end)

      assert %Error{caused_by: [error1, error2]} = new_error
      assert new_error.file === file
      assert new_error.line === 42
      assert error1.file === file
      assert error1.line === 42
      assert error2.file === file
      assert error2.line === 42
    end
  end
end
