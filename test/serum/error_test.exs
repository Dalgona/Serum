defmodule Serum.ErrorTest do
  use ExUnit.Case, async: true

  alias Serum.Error
  alias Serum.Error.Format
  alias Serum.Error.SimpleMessage

  setup_all do
    error = %Error{
      message: %SimpleMessage{text: "test error"},
      caused_by: [],
      file: %Serum.File{src: "testfile"},
      line: 3
    }

    {:ok, error: error}
  end

  describe "with text formatter" do
    test "the formatted text contains the error message", ctx do
      text = make_string(ctx.error)

      assert text =~ "test error"
    end

    test "the formatted text contains file and line information if available", ctx do
      text = make_string(ctx.error)

      assert text =~ "testfile:3: "
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

      text = make_string(error)

      assert text =~ "test error"
      assert text =~ "nested error"
    end
  end

  defp make_string(error) do
    error
    |> Format.format_text(0)
    |> IO.ANSI.format()
    |> IO.iodata_to_binary()
  end
end
