defprotocol Serum.Error.Format do
  @moduledoc """
  A protocol responsible for converting error messages or error data
  into various formats.
  """

  @type t :: term()

  @doc "Converts the given object into text suitable for terminal output."
  @spec format_text(t(), non_neg_integer()) :: IO.ANSI.ansidata()
  def format_text(item, indent)

  @doc "Converts the given object into HTML markup."
  @spec format_html(t()) :: iodata()
  def format_html(item)
end
