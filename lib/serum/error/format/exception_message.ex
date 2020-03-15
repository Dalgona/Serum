defimpl Serum.Error.Format, for: Serum.V2.Error.ExceptionMessage do
  alias Serum.V2.Error.ExceptionMessage

  @spec format_text(ExceptionMessage.t(), non_neg_integer()) :: IO.ANSI.ansidata()
  def format_text(%ExceptionMessage{} = msg, _indent) do
    [
      "an error was raised:\n",
      :red,
      Exception.format_banner(:error, msg.exception),
      [:light_black, ?\n],
      Exception.format_stacktrace(msg.stacktrace),
      :reset
    ]
  end
end
