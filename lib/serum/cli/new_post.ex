defmodule Serum.CLI.NewPost do
  @moduledoc false

  use Serum.CLI.Task
  import Serum.Util

  @strict [
    title: :string,
    tag: :keep,
    output: :string
  ]
  @aliases [
    t: :title,
    g: :tag,
    o: :output
  ]
  @required [:title, :output]

  def tasks, do: ["newpost"]

  def run(_, args) do
    case OptionParser.parse(args, strict: @strict, aliases: @aliases) do
      {_, _, [{invalid, _} | _]} ->
        warn("Invalid option: #{invalid}")
        {:cli_exit, 2}

      {opts, _, []} ->
        do_run(opts)
    end
  end

  @spec do_run(keyword()) :: {:cli_exit, non_neg_integer()}
  defp do_run(opts) do
    with [] <- check_required(opts),
         {:ok, now} <- current_datetime(),
         path = full_path(opts[:output], now),
         {:ok, file} <- create_file(path) do
      IO.write(file, generate_contents(opts, now))
      File.close(file)
      msg_gen(path)
      {:cli_exit, 0}
    else
      # From check_required/1:
      [required | _] ->
        warn("`#{required}` option is required, but it is not given.")
        {:cli_exit, 2}

      # From current_datetime/0:
      :error ->
        warn("System timezone is not properly set.")
        {:cli_exit, 1}

      # From create_file/1:
      {:error, reason} ->
        reason_str = :file.format_error(reason)
        warn("Could not create a new file: #{reason_str}")
        {:cli_exit, 1}
    end
  end

  @spec check_required(keyword()) :: [atom()]
  defp check_required(opts) do
    Enum.filter(@required, &(&1 not in Keyword.keys(opts)))
  end

  @spec current_datetime() :: {:ok, DateTime.t()} | :error
  defp current_datetime do
    {:ok, Timex.local()}
  rescue
    _ -> :error
  end

  @spec full_path(binary(), DateTime.t()) :: binary()
  defp full_path(output, now) do
    date_part =
      [now.year, now.month, now.day]
      |> Enum.map(&(&1 |> to_string() |> String.pad_leading(2, "0")))
      |> Enum.join("-")

    Path.join("posts/", date_part <> "-" <> output <> ".md")
  end

  @spec create_file(binary()) :: {:ok, pid()} | {:error, File.posix()}
  defp create_file(path) do
    dirname = Path.dirname(path)

    unless File.exists?(dirname) do
      File.mkdir_p!(dirname)
      msg_mkdir(dirname)
    end

    File.open(path, [:write, :exclusive, :utf8])
  end

  @spec generate_contents(keyword(), DateTime.t()) :: binary()
  defp generate_contents(opts, now) do
    """
    ---
    title: #{opts[:title]}
    date: #{Timex.format!(now, "{YYYY}-{0M}-{0D} {h24}:{m}:{s}")}
    tags: #{opts |> Keyword.get_values(:tag) |> Enum.join(", ")}
    ---

    TODO: Write some text here!
    """
  end

  def short_help(_task), do: "Add a new blog post to the current project"

  def synopsis(_task), do: "serum newpost [OPTIONS]"

  def help(_task),
    do: """
    `serum newpost` task helps you add a new post to your project. Some necessary
    directories may be created during the process.

    Post date will be automatically set to the moment this task is executed.

    ## OPTIONS

    * `-t, --title`: Title of the new post. This option is required.
    * `-g, --tag`: Tag(s) of the new post. You can provide this option zero or
      more times to give multiple tags to the post.
    * `-o, --output`: Name of the generated post file. The actual path to the
      generated file will be in the form of `posts/YYYY-MM-DD-<output>.md`.
      This option is required.
    """
end
