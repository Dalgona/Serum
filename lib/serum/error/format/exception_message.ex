defimpl Serum.Error.Format, for: Serum.V2.Error.ExceptionMessage do
  require EEx
  alias Serum.V2.Error.ExceptionMessage

  @spec format_text(ExceptionMessage.t(), non_neg_integer()) :: IO.ANSI.ansidata()
  def format_text(%ExceptionMessage{} = msg, _indent) do
    [
      "an error was raised:\n",
      :red,
      Exception.format_banner(:error, trim_exception(msg.exception)),
      [:light_black, ?\n],
      Exception.format_stacktrace(msg.stacktrace),
      :reset
    ]
  end

  eex_file =
    :serum
    |> :code.priv_dir()
    |> Path.join("build_resources/exception_message.html.eex")

  EEx.function_from_file(:defp, :template, eex_file, [:message])

  @spec format_html(ExceptionMessage.t()) :: iodata()
  def format_html(%ExceptionMessage{} = msg), do: template(msg)

  @spec trim_exception(Exception.t()) :: Exception.t()
  defp trim_exception(exception)

  defp trim_exception(%KeyError{term: %{__struct__: struct} = map} = exception) do
    trimmed_term =
      map
      |> Map.from_struct()
      |> trim_map()
      |> Map.put(:__struct__, struct)

    %KeyError{exception | term: trimmed_term}
  end

  defp trim_exception(%KeyError{term: %{} = map} = exception) do
    %KeyError{exception | term: trim_map(map)}
  end

  defp trim_exception(exception), do: exception

  @spec trim_map(map()) :: map()
  defp trim_map(map) do
    Map.new(map, fn
      {key, string} when is_binary(string) -> {key, "..."}
      {key, list} when is_list(list) -> {key, ["..."]}
      {key, map} when is_map(map) -> {key, %{"..." => "..."}}
      {key, tuple} when is_tuple(tuple) -> {key, {"..."}}
      {key, value} -> {key, value}
    end)
  end

  # Implementation taken from the Elixir source code.
  defp format_location(opts) when is_list(opts) do
    Exception.format_file_line(Keyword.get(opts, :file), Keyword.get(opts, :line), " ")
  end

  # Implementation taken from the Elixir source code.
  defp format_application(module) do
    case :application.get_application(module) do
      {:ok, app} ->
        case :application.get_key(app, :vsn) do
          {:ok, vsn} when is_list(vsn) ->
            "(" <> Atom.to_string(app) <> " " <> List.to_string(vsn) <> ") "

          _ ->
            "(" <> Atom.to_string(app) <> ") "
        end

      :undefined ->
        ""
    end
  end
end
