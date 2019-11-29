defmodule Serum.Error do
  @moduledoc "Defines a struct describing error information."

  alias Serum.Error.Format

  defstruct [:message, :exception, :stacktrace, :caused_by, :file, :line]

  @type t :: %__MODULE__{
          message: Format.t(),
          caused_by: [t()],
          file: Serum.File.t() | nil,
          line: integer()
        }

  defimpl Format do
    def format_text(error, indent) do
      file_text = format_file_text(error.file, error.line)
      head = indented([file_text, Format.format_text(error.message, 0)], indent)
      children = Enum.map(error.caused_by, &Format.format_text(&1, indent + 1))

      Enum.intersperse([head | children], ?\n)
    end

    @spec format_file_text(Serum.File.t() | nil, integer()) :: binary()
    defp format_file_text(maybe_file, line)
    defp format_file_text(nil, _line), do: ""

    defp format_file_text(%Serum.File{src: src}, line) do
      case Exception.format_file_line(src, line) do
        "" -> ""
        str when is_binary(str) -> [str, ?\s]
      end
    end

    @spec indented(IO.ANSI.ansidata(), non_neg_integer()) :: IO.ANSI.ansidata()
    defp indented(str, indent)
    defp indented(str, 0), do: str

    defp indented(str, indent) do
      [List.duplicate("  ", indent - 1), :red, "- ", :reset, str]
    end
  end
end
