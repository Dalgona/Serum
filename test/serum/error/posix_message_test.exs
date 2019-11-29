defmodule Serum.Error.POSIXMessageTest do
  use ExUnit.Case, async: true

  alias Serum.Error.Format
  alias Serum.Error.POSIXMessage

  setup_all do
    message = %POSIXMessage{reason: :enoent}

    {:ok, message: message}
  end

  describe "with text formatter" do
    test "the formatted text contains the string representation of POSIX error", ctx do
      text =
        ctx.message
        |> Format.format_text(0)
        |> IO.ANSI.format()
        |> IO.iodata_to_binary()

      assert text =~ "no such file or directory"
    end
  end
end
