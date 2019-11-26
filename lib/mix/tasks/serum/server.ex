defmodule Mix.Tasks.Serum.Server do
  @moduledoc """
  Starts the Serum development server.

      mix serum.server [(-p|--port) PORT]

  This task builds the current Serum project at a temporary directory, and
  starts the development server. The server uses the port `8080` by default.

  ## Options

  - `-p(--port)` (integer): Use a specific port instead of `8080`. This is
    useful when the default port is not available for use.
  """

  @shortdoc "Starts the Serum development server"

  use Mix.Task
  alias Mix.Tasks.Serum.CLIHelper
  alias OptionParser.ParseError
  alias Serum.DevServer
  alias Serum.Result

  @options [
    strict: [port: :integer],
    aliases: [p: :port]
  ]

  @impl true
  def run(args) do
    Mix.Project.compile([])
    Mix.shell().info(CLIHelper.version_string())

    {options, argv} = OptionParser.parse!(args, @options)

    if argv != [] do
      raise ParseError, "\nExtra arguments: #{Enum.join(argv, ", ")}"
    end

    {:ok, _} = Application.ensure_all_started(:serum)

    case DevServer.run("", options[:port] || 8080) do
      {:ok, _pid} ->
        DevServer.Prompt.start(allow_detach: false)

      {:error, _} = error ->
        Result.show(error)
        System.halt(1)
    end
  end
end
