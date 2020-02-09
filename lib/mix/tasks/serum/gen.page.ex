defmodule Mix.Tasks.Serum.Gen.Page do
  @moduledoc """
  Adds a new page to the current project.

      mix serum.gen.page (-t|--title) TITLE (-o|--output) OUTPUT [Options]

  ## Required Options

  - `-t(--title)` (string): Title of the new page.
  - `-o(--output)` (string): The path where the new page will be saved,
    relative to `pages/` directory. It must end with one of `.md`, `.html`,
    or `.html.eex`.

  ## Other Options

  - `-l(--label)` (string): Label of the new page. Defaults to the page title.
  - `-g(--group)` (string): Name of a group the new page belongs to.
  - `-r(--order)` (integer): The order of the new page in a group.
    Defaults to `0`.
  """

  @shortdoc "Adds a new page to the current project"

  use Mix.Task
  alias Mix.Generator, as: MixGen
  alias OptionParser.ParseError
  alias Serum.CLIUtils

  @options [
    strict: [
      title: :string,
      label: :string,
      group: :string,
      order: :integer,
      output: :string
    ],
    aliases: [
      t: :title,
      l: :label,
      g: :group,
      r: :order,
      o: :output
    ]
  ]

  @required [:title, :output]
  @in_header [:title, :label, :group, :order]

  @impl true
  def run(args) do
    options = CLIUtils.parse_options(args, @options)
    :ok = check_required!(options)
    type = check_type!(options[:output])
    output = Path.join("pages/", options[:output])
    options2 = apply_default(options)

    header =
      options2
      |> Enum.filter(fn {k, _v} -> k in @in_header end)
      |> Enum.map(fn {k, v} -> "#{k}: #{v}" end)
      |> Enum.join("\n")

    title = options2[:title]

    {title, body} =
      case type do
        :md ->
          {"# #{title}", "TODO: Put some contents here!"}

        _ ->
          {"<h1>#{title}</h1>", "<p>TODO: Put some contents here!</p>"}
      end

    if not File.exists?("pages") do
      MixGen.create_directory("pages")
    end

    MixGen.create_file(output, "---\n#{header}\n---\n\n#{title}\n\n#{body}\n")
  end

  defp check_required!(opts) do
    case @required -- Keyword.keys(opts) do
      [] -> :ok
      [x | _] -> raise ParseError, "\nExpected \"--#{x}\" option to be given"
    end
  end

  defp check_type!(path) do
    cond do
      String.ends_with?(path, ".md") ->
        :md

      String.ends_with?(path, ".html") ->
        :html

      String.ends_with?(path, ".html.eex") ->
        :eex

      :else ->
        Mix.raise("Output file type must be one of .md, .html, or .html.eex")
    end
  end

  defp apply_default(options) do
    Keyword.merge([label: options[:title], order: 0], options)
  end
end
