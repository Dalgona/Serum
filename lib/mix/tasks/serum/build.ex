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

  use Mix.Task
  alias IO.ANSI, as: A
  alias Serum.Build
  alias Serum.CLIUtils
  alias Serum.Project
  alias Serum.Project.Loader, as: ProjectLoader

  @options [
    strict: [output: :string],
    aliases: [o: :output]
  ]

  @impl true
  @spec run(any) :: any()
  def run(args) do
    Mix.Project.compile([])

    options = CLIUtils.parse_options(args, @options)
    dest = options[:output] || "site"
    {:ok, _} = Application.ensure_all_started(:serum)

    Mix.shell().info(CLIUtils.version_string())

    with {:ok, %Project{} = proj} <- ProjectLoader.load(""),
         {:ok, ^dest} <- Build.build(proj, "", dest) do
      """

      #{A.bright()}Your website is now ready!#{A.reset()}
      Copy(or move) the contents of `#{dest}` directory
      into your public webpages directory.
      """
      |> String.trim_trailing()
      |> Mix.shell().info()
    else
      {:error, _} = error ->
        Serum.Result.show(error)
        Mix.raise("could not build the website due to above error(s)")
    end
  end
end
