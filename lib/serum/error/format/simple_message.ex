defimpl Serum.Error.Format, for: Serum.V2.Error.SimpleMessage do
  alias Serum.V2.Error.SimpleMessage

  @spec format_text(SimpleMessage.t(), non_neg_integer()) :: IO.ANSI.ansidata()
  def format_text(%SimpleMessage{text: text}, _indent), do: text

  @spec format_html(SimpleMessage.t()) :: iodata()
  def format_html(%SimpleMessage{} = _msg) do
    ~s(<span style="color: red;">Protocol not implemented for SimpleMessage.</span>)
  end
end
