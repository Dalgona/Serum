defmodule Mix.Tasks.Serum.Gen.Post do
  @moduledoc """
  Adds a new blog post to the current project.

      mix serum.gen.post (-t|--title) TITLE (-o|--output) OUTPUT [Options]

  Post date will be automatically set to the moment this task is executed.

  ## Required Options

  - `-t(--title)` (string): Title of the new blog post.
  - `-o(--output)` (string): Name of the generated post file. The actual path
    to the generated file will be in the form of
    `posts/YYYY-MM-DD-<OUTPUT>.md`.

  ## Other Options

  - `-g(--tag)` (string): Tag(s) of the new post. You can provide this option
    zero or more times to give multiple tags to the post.
  """

  @shortdoc "Adds a new blog post to the current project"

  use Mix.Task
  alias Mix.Generator, as: MixGen
  alias OptionParser.ParseError
  alias Serum.CLIUtils

  @options [
    strict: [
      title: :string,
      tag: :keep,
      output: :string
    ],
    aliases: [
      t: :title,
      g: :tag,
      o: :output
    ]
  ]

  @required [:title, :output]

  @impl true
  def run(args) do
    options = CLIUtils.parse_options(args, @options)
    {:ok, _} = Application.ensure_all_started(:timex)
    :ok = check_required!(options)
    now = get_now!()
    path = get_path(options[:output], now)

    if not File.exists?("posts") do
      MixGen.create_directory("posts")
    end

    tags =
      case Keyword.get_values(options, :tag) do
        [] -> ""
        list -> "tags: #{Enum.join(list, ", ")}\n"
      end

    MixGen.create_file(
      path,
      """
      ---
      title: #{options[:title]}
      date: #{Timex.format!(now, "{YYYY}-{0M}-{0D} {h24}:{m}:{s}")}
      #{tags}---

      TODO: Put some contents here!
      """
    )
  end

  defp check_required!(opts) do
    case @required -- Keyword.keys(opts) do
      [] -> :ok
      [x | _] -> raise ParseError, "\nExpected \"--#{x}\" option to be given"
    end
  end

  defp get_now! do
    Timex.local()
  rescue
    _ -> Mix.raise("System timezone is not properly set")
  end

  defp get_path(output, now) do
    date_part =
      [now.year, now.month, now.day]
      |> Enum.map(&(&1 |> to_string() |> String.pad_leading(2, "0")))
      |> Enum.join("-")

    Path.join("posts/", date_part <> "-" <> output <> ".md")
  end
end
