defmodule Mix.Tasks.Serum.Build do
  @moduledoc """
  Builds the Serum project at the specified directory.

      mix serum.build [(-o|--output) PATH]

  The website will be built into `PATH` if `-o(--output) PATH` option is given,
  otherwise `/path/to/project/site` directory.

  If the output directory exists and is not empty, all files and directories
  under that directory will be deleted before the build process begins.
  However, any files or directories which names start with a dot (`.`) are
  preserved, as they may contain important information such as version
  control-related data.

  ## Options

  - `-o(--output)` (string): Specifies the output directory. Defaults to
    `/path/to/project/site`.
  """

  @shortdoc "Builds the Serum project"

  @options [
    strict: [output: :string],
    aliases: [o: :output]
  ]

  use Mix.Task

  @impl true
  def run(args) do
  end
end
