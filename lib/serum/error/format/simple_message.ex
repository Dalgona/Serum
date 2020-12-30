defimpl Serum.Error.Format, for: Serum.V2.Error.SimpleMessage do
  require EEx
  alias Serum.V2.Error.SimpleMessage

  @spec format_text(SimpleMessage.t(), non_neg_integer()) :: IO.ANSI.ansidata()
  def format_text(%SimpleMessage{text: text}, _indent), do: text

  eex_file =
    :serum
    |> :code.priv_dir()
    |> Path.join("build_resources/simple_message.html.eex")

  EEx.function_from_file(:defp, :template, eex_file, [:message])

  @spec format_html(SimpleMessage.t()) :: iodata()
  def format_html(%SimpleMessage{} = msg), do: template(msg)
end
