defmodule Serum.Error.Format.SimpleMessageTest do
  use ExUnit.Case, async: true

  alias Serum.Error.Format
  alias Serum.V2.Error.SimpleMessage

  setup_all do
    message = %SimpleMessage{text: "test error"}

    {:ok, message: message}
  end

  describe "with text formatter" do
    test "the formatted text contains simple text message", ctx do
      text =
        ctx.message
        |> Format.format_text(0)
        |> IO.ANSI.format()
        |> IO.iodata_to_binary()

      assert text =~ "test error"
    end
  end
end
