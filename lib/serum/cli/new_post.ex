defmodule Serum.CLI.NewPost do
  @moduledoc false

  use Serum.CLI.Task

  @strict  [edit: :boolean]
  @aliases [e: :edit]

  def tasks, do: ["newpost"]

  def run(_, args) do
    raise "not implemented"
    {:cli_exit, 0}
  end

  def short_help(_task), do: "Add a new blog post to the current project"

  def synopsis(_task), do: "serum newpost [OPTIONS]"

  def help(_task), do: """
  `serum newpost` task provides interactive user interface for adding a new blog
  post to your project. Some necessary directories may be created during the
  process.

  ## OPTIONS

  * `-e, --edit`: Edit the file after creation. This option will not work unless
    the `EDITOR` environment variable is set and valid.
  """
end
