defmodule Serum.CLI.Build do
  @moduledoc false

  alias Serum.CLI
  alias Serum.CLI.Task, as: CLITask
  alias Serum.Error
  alias Serum.SiteBuilder

  @behaviour CLITask

  @strict  [parallel: :boolean, output: :string]
  @aliases [p: :parallel, o: :output]

  def tasks, do: ["build"]

  def run(_task, args) do
    {opts, args, errors} =
      OptionParser.parse args, strict: @strict, aliases: @aliases
    mode = opts[:parallel] && :parallel || :sequential
    out = opts[:output]
    case {args, errors} do
      {args, []} -> launch_build args, out, mode
      {_, _error} -> CLI.usage()
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
    else
      {:error, _, _} = error -> on_error error
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
end
