defmodule Serum.Error.Format.CycleMessageTest do
  use Serum.Case, async: true

  alias Serum.Error.Format
  alias Serum.V2.Error.CycleMessage

  setup_all do
    message = %CycleMessage{cycle: ["foo", :bar, 'baz']}

    {:ok, message: message}
  end

  describe "with text formatter" do
    test "the formatted text contains cycle information", ctx do
      text =
        ctx.message
        |> Format.format_text(0)
        |> IO.ANSI.format()
        |> IO.iodata_to_binary()

      Enum.each(~w(foo bar baz), fn name ->
        assert text =~ name
      end)
    end
  end
end
