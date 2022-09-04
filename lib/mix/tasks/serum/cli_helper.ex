defmodule Mix.Tasks.Serum.CLIHelper do
  @moduledoc false

  @version Mix.Project.config()[:version]

  @spec version_string() :: binary()
  def version_string do
    [
      :bright,
      "Serum -- Yet another simple static website generator\n",
      "Version #{@version}. Copyright (C) 2022 Dalgona. ",
      "<project-serum@dalgona.dev>\n",
      :reset
    ]
    |> IO.ANSI.format()
    |> IO.iodata_to_binary()
  end

  @spec parse_options([binary()], OptionParser.options()) :: keyword() | no_return()
  def parse_options(args, options) do
    options = put_in(options[:strict][:color], :boolean)
    {options, argv} = OptionParser.parse!(args, options)
    :ok = set_ansi(options[:color])

    if argv != [] do
      extras = Enum.join(argv, ", ")

      raise OptionParser.ParseError, "\nExtra arguments: #{extras}"
    end

    options
  end

  defp set_ansi(value)
  defp set_ansi(nil), do: :ok

  defp set_ansi(value) when is_boolean(value) do
    Application.put_env(:elixir, :ansi_enabled, value)
  end
end
