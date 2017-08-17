defmodule Serum.CLI.Init do
  @moduledoc false

  alias Serum.CLI
  alias Serum.CLI.Task, as: CLITask
  alias Serum.Error
  alias Serum.Init

  @behaviour CLITask

  @strict  [force: :boolean]
  @aliases [f: :force]

  def tasks, do: ["init"]

  def run(_task, args) do
    {opts, args, errors} =
      OptionParser.parse args, strict: @strict, aliases: @aliases
    force? = opts[:force] || false
    with [] <- errors,
         dir = List.first(args) || ".",
         :ok <- Init.init(dir, force?)
    do
      IO.puts """

      \x1b[1mSuccessfully initialized a new Serum project!
      try `serum build #{dir}` to build the site.\x1b[0m
      """
      {:cli_exit, 0}
    else
      x when is_list(x) ->
        CLI.usage()
        {:cli_exit, 2}
      {:error, _} = error ->
        Error.show error
        IO.puts """

        Could not initialize a new project.
        Make sure the target directory is writable.
        """
        {:cli_exit, 1}
    end
  end

  def short_help(_task), do: "Initialize a new Serum project"

  def synopsis(_task), do: "serum init [OPTIONS] [DIR]"

  def help(_task), do: """
  `serum init` initializes a new Serum project into `DIR` directory, or the
  current working directory if `DIR` is not given. New directories will be
  created if needed. By default, Serum refuses to initialize a new project if
  `DIR` already exists and is not empty. This behavior can be overriden if
  executed with `-f (--force)` option.

  ## OPTIONS

  * `-f, --force`: Forces initialization even if `DIR` is not empty.
  """
end
