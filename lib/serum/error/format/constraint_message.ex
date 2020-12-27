defimpl Serum.Error.Format, for: Serum.V2.Error.ConstraintMessage do
  alias Serum.V2.Error.ConstraintMessage

  @spec format_text(ConstraintMessage.t(), non_neg_integer()) :: IO.ANSI.ansidata()
  def format_text(%ConstraintMessage{} = msg, _indent) do
    [
      "value of ",
      [:bright, :yellow, to_string(msg.name), :reset],
      [" property (", inspect(msg.value), ") "],
      "violates the constraint ",
      [:bright, :yellow, msg.constraint, :reset]
    ]
  end

  @spec format_html(ConstraintMessage.t()) :: iodata()
  def format_html(%ConstraintMessage{} = _msg) do
    ~s(<span style="color: red;">Protocol not implemented for ConstraintMessage.</span>)
  end
end
