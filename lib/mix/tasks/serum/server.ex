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
  alias Serum.DevServer

  @options [
    strict: [port: :integer],
    aliases: [p: :port]
  ]

  @impl true
  def run(args) do
    Mix.Project.compile([])

    options = CLIHelper.parse_options(args, @options)
    {:ok, _} = Application.ensure_all_started(:serum)

    Mix.shell().info(CLIHelper.version_string())

    case DevServer.run("", options[:port] || 8080) do
      {:ok, _pid} ->
        DevServer.Prompt.start(allow_detach: false)

      {:error, _} = error ->
        Serum.Result.show(error)
        System.halt(1)
    end
  end
end
