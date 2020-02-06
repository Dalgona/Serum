defmodule Serum.V2.Error.MessageTest do
  use ExUnit.Case, async: true
  alias Serum.V2.Error.CycleMessage
  alias Serum.V2.Error.ExceptionMessage
  alias Serum.V2.Error.POSIXMessage
  alias Serum.V2.Error.SimpleMessage

  describe "CycleMessage.message/1" do
    test "creates a CycleMessage struct" do
      cycle = ~w[foo bar baz]
      message = CycleMessage.message([cycle])

      assert message.cycle === cycle
    end
  end

  describe "ExceptionMessage.message/1" do
    test "creates an ExceptionMessage struct" do
      {e, stacktrace} = exception()
      message = ExceptionMessage.message([e, stacktrace])

      assert %RuntimeError{message: "test error"} = message.exception
      assert is_list(message.stacktrace)
    end
  end

  describe "POSIXMessage.message/1" do
    test "creates an POSIXMessage struct" do
      assert %POSIXMessage{reason: :enoent} = POSIXMessage.message([:enoent])
    end
  end

  describe "SimpleMessage.message/1" do
    test "creates an SimpleMessage struct" do
      assert %SimpleMessage{text: "foo"} = SimpleMessage.message(["foo"])
    end
  end

  defp exception do
    raise "test error"
  rescue
    e in RuntimeError -> {e, __STACKTRACE__}
  end
end
