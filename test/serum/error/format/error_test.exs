defmodule Serum.Error.Format.ErrorTest do
  use ExUnit.Case, async: true

  alias Serum.Error.SimpleMessage
  alias Serum.V2
  alias Serum.V2.Error

  setup_all do
    error = %Error{
      message: %SimpleMessage{text: "test error"},
      caused_by: [],
      file: %V2.File{src: "testfile"},
      line: 3
    }

    {:ok, error: error}
  end

  describe "with text formatter" do
    test "the formatted text contains the error message", ctx do
      assert to_string(ctx.error) =~ "test error"
    end

    test "the formatted text contains file and line information if available", ctx do
      assert to_string(ctx.error) =~ "testfile:3: "
    end

    test "formats nested errors", ctx do
      nested_error = %Error{
        ctx.error
        | message: %SimpleMessage{text: "nested error"}
      }

      error = %Error{
        ctx.error
        | caused_by: [nested_error]
      }

      text = to_string(error)

      assert text =~ "test error"
      assert text =~ "nested error"
    end
  end
end
