defimpl Serum.Error.Format, for: Serum.V2.Error.POSIXMessage do
  alias Serum.V2.Error.POSIXMessage

  @spec format_text(POSIXMessage.t(), non_neg_integer()) :: IO.ANSI.ansidata()
  def format_text(%POSIXMessage{reason: reason}, _indent) do
    :file.format_error(reason)
  end
end
