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
    else
      x when is_list(x) -> CLI.usage()
      {:error, _, _} = error ->
        Error.show error
        IO.puts """

        Could not initialize a new project.
        Make sure the target directory is writable.
        """
        System.halt 1
    end
  end
end
