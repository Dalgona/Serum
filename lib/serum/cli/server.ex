defmodule Serum.CLI.Server do
  alias Serum.CLI
  alias Serum.CLI.Task, as: CLITask
  alias Serum.DevServer

  @behaviour CLITask

  @strict  [port: :integer]
  @aliases [p: :port]

  def run(_task, args) do
    {opts, args, errors} =
      OptionParser.parse args, strict: @strict, aliases: @aliases
    port = opts[:port] || 8080
    case {args, errors} do
      {[], []} -> DevServer.run ".", port
      {[dir|_], []} -> DevServer.run dir, port
      {_, _error} -> CLI.usage()
    end
  end
end
