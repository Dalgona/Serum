defimpl Serum.Error.Format, for: Serum.V2.Error.POSIXMessage do
  require EEx
  alias Serum.V2.Error.POSIXMessage

  @spec format_text(POSIXMessage.t(), non_neg_integer()) :: IO.ANSI.ansidata()
  def format_text(%POSIXMessage{reason: reason}, _indent) do
    :file.format_error(reason)
  end

  eex_file =
    :serum
    |> :code.priv_dir()
    |> Path.join("build_resources/posix_message.html.eex")

  EEx.function_from_file(:defp, :template, eex_file, [:message])

  @spec format_html(POSIXMessage.t()) :: iodata()
  def format_html(%POSIXMessage{} = message), do: template(message)
end
