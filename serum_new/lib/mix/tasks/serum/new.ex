defmodule Mix.Tasks.Serum.New do
  @moduledoc """
  Creates a new Serum project.

      mix serum.new [--force] PATH

  A new Serum project will be created at the given `PATH`. `PATH` cannot be
  omitted and it must start with a lowercase ASCII letter, followed by zero
  or more lowercase ASCII letters, digits, or underscores.

  This task will fail if `PATH` already exists and is not empty. This behavior
  will be overridden if the task is executed with a `--force` option.

  ## Required Argument

  - `PATH`: A path where the new Serum project will be created.

  ## Options

  - `--force` (boolean): Forces creation of the new Serum project even if
    `PATH` is not empty.
  """

  @shortdoc "Creates a new Serum project"

  use Mix.Task

  @impl true
  def run(args) do
    Mix.raise("not implemented. Argument(s): #{inspect(args)}")

    # Things to implement:
    # - Parse command line arguments using OptionParser
    # - Check if `args` contains PATH
    # - Check if PATH already exists and is not empty (or --force is given)
    # - Check if PATH matches the pattern ~r/[a-z][a-z0-9_]*/
    # - After all checks has passed,
    #   - Create directory structure
    #   - Create files
    #   - Print completion message
  end
end
