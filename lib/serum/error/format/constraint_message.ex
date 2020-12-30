defimpl Serum.Error.Format, for: Serum.V2.Error.ConstraintMessage do
  require EEx
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

  eex_file =
    :serum
    |> :code.priv_dir()
    |> Path.join("build_resources/constraint_message.html.eex")

  EEx.function_from_file(:defp, :template, eex_file, [:message])

  @spec format_html(ConstraintMessage.t()) :: iodata()
  def format_html(%ConstraintMessage{} = message), do: template(message)
end
