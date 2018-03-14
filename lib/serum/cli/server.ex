defmodule Serum.CLI.Server do
  @moduledoc false

  use Serum.CLI.Task
  alias Serum.DevServer

  @strict [port: :integer]
  @aliases [p: :port]

  def tasks, do: ["server"]

  def run(_task, args) do
    {opts, args, errors} =
      OptionParser.parse(
        args,
        strict: @strict,
        aliases: @aliases
      )

    port = opts[:port] || 8080

    case {args, errors} do
      {[], []} ->
        DevServer.run(".", port)
        {:cli_exit, 0}

      {[dir | _], []} ->
        DevServer.run(dir, port)
        {:cli_exit, 0}

      {_, _error} ->
        CLI.usage()
        {:cli_exit, 2}
    end
  end

  def short_help(_task), do: "Start Serum development server"

  def synopsis(_task), do: "serum server [OPTIONS] [DIR]"

  def help(_task),
    do: """
    `serum server` builds a Serum project located in `DIR` directory (or current
    working directory if `DIR` is not given) into a temporary directory, and
    starts the development server. By default, the Serum development server uses
    port 8080, but you can override this with `-p (--port)` option.

    ## OPTIONS

    * `-p, --port <PORT>`: If the default port (8080) is unavailable for some
      reason, you can use this option to specify alternative port number.

    ## NOTE

    1. Once the Serum development server has started, you can interact with the
      server by typing commands. To see a list of available commands, type `help`
      in the server prompt.
    2. Always type `quit` command to stop the server. Pressing Control-C causes
      unclean exit, leaving the temporary directory not removed.
    """
end
