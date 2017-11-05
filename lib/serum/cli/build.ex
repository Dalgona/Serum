defmodule Serum.CLI.Build do
  @moduledoc false

  use Serum.CLI.Task
  alias Serum.SiteBuilder

  @strict  [parallel: :boolean, output: :string]
  @aliases [p: :parallel, o: :output]

  def tasks, do: ["build"]

  def run(_task, args) do
    {opts, args, errors} =
      OptionParser.parse args, strict: @strict, aliases: @aliases
    mode = opts[:parallel] && :parallel || :sequential
    out = opts[:output]
    case {args, errors} do
      {args, []} ->
        launch_build args, out, mode
      {_, _error} ->
        CLI.usage()
        {:cli_exit, 2}
    end
  end

  @spec launch_build([binary], binary, Serum.Build.mode) :: any

  defp launch_build(args, out, mode) do
    dir =
      case args do
        [] -> "."
        [dir|_] -> dir
      end
    with {:ok, pid} <- SiteBuilder.start_link(dir, out),
         {:ok, _} <- SiteBuilder.load_info(pid),
         {:ok, dest} <- SiteBuilder.build(pid, mode)
    do
      on_finish dest
      {:cli_exit, 0}
    else
      {:error, _} = error ->
        on_error error
        {:cli_exit, 1}
    end
  end

  @spec on_finish(binary) :: :ok

  defp on_finish(dest) do
    IO.puts """

    \x1b[1mYour website is now ready!
    Copy(move) the contents of `#{dest}` directory
    into your public webpages directory.\x1b[0m
    """
  end

  @spec on_error(Error.error) :: :ok

  defp on_error(error) do
    Error.show(error)
    IO.puts """

    Could not build the website due to error(s).
    Please fix the problems shown above and try again.
    """
  end

  def short_help(_task), do: "Build an existing Serum project"

  def synopsis(_task), do: "serum build [OPTIONS] [DIR]"

  def help(_task), do: """
  `serum build` builds an existing Serum project located in `DIR` directory, or
  the current working directory if `DIR` is not given.

  ## OPTIONS

  * `-p, --parallel`: If this option is used, Serum accelerates the build
    process by processing source files parallelly. Otherwise, Serum processes
    source files one by one.
  * `-o, --output <OUTDIR>`: Specifies the directory where output files are
    stored. If this option is not used, the project will built under
    </path/to/project>/site directory.

  ## NOTE

  If the output directory exists and is not empty, all files and directories
  under that directory will be deleted before the build process begins. However,
  files and directories which names start with a dot (`.`) are preserved as they
  may contain important information, such as version control-releated data.
  """
end
