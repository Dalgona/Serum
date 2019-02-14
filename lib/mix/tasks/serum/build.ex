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
  alias OptionParser.ParseError
  alias Serum.Result
  alias Serum.SiteBuilder

  @version Mix.Project.config()[:version]

  @options [
    strict: [output: :string],
    aliases: [o: :output]
  ]

  @impl true
  def run(args) do
    Mix.Project.compile([])

    """
    #{A.bright()}Serum -- Yet another simple static website generator
    Version #{@version}. Copyright (C) 2018 Dalgona. <dalgona@hontou.moe>
    #{A.reset()}
    """
    |> String.trim_trailing()
    |> Mix.shell().info()

    {options, argv} = OptionParser.parse!(args, @options)
    out = options[:output]

    if argv != [] do
      raise ParseError, "\nExtra arguments: #{Enum.join(argv, ", ")}"
    end

    {:ok, _} = Application.ensure_all_started(:serum)

    with {:ok, pid} <- SiteBuilder.start_link(File.cwd!(), out),
         {:ok, _info} <- SiteBuilder.load_info(pid),
         {:ok, dest} <- SiteBuilder.build(pid) do
      """

      #{A.bright()}Your website is now ready!#{A.reset()}
      Copy(or move) the contents of `#{dest}` directory
      into your public webpages directory.
      """
      |> String.trim_trailing()
      |> Mix.shell().info()
    else
      {:error, _} = error ->
        Result.show(error)
        Mix.raise("could not build the website due to above error(s)")
    end
  end
end
