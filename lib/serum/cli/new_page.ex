defmodule Serum.CLI.NewPage do
  @moduledoc false

  use Serum.CLI.Task

  @strict  [edit: :boolean]
  @aliases [e: :edit]

  def tasks, do: ["newpage"]

  def run(_, args) do
    raise "not implemented"
    {:cli_exit, 0}
  end

  def short_help(_task), do: "Add a new page to the current project"

  def synopsis(_task), do: "serum newpage [OPTIONS]"

  def help(_task), do: """
  `serum newpage` task provides interactive user interface for adding a new page
  to your project. Some necessary directories may be created during the process.

  ## OPTIONS

  * `-e, --edit`: Edit the file after creation. This option will not work unless
    the `EDITOR` environment variable is set and valid.
  """
end
