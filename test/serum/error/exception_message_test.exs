defmodule Serum.Error.ExceptionMessageTest do
  use ExUnit.Case, async: true

  alias Serum.Error.ExceptionMessage
  alias Serum.Error.Format

  setup_all do
    {exception, stacktrace} =
      try do
        raise ArgumentError
      rescue
        e -> {e, __STACKTRACE__}
      end

    message = %ExceptionMessage{exception: exception, stacktrace: stacktrace}

    {:ok, message: message}
  end

  describe "with text formatter" do
    test "the formatted text contains the exception message", ctx do
      text =
        ctx.message
        |> Format.format_text(0)
        |> IO.ANSI.format()
        |> IO.iodata_to_binary()

      assert text =~ "ArgumentError"
      assert text =~ "argument error"
    end
  end
end
