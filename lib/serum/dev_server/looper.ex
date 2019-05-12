defmodule Serum.DevServer.Looper do
  @moduledoc """
  A looper which accepts user inputs as server commands and processes them.
  """

  import Serum.Util
  alias Serum.DevServer.Service

  @service Application.get_env(:serum, :service, Service.GenServer)

  @doc "Starts the infinite command prompt loop."
  @spec looper() :: no_return()
  def looper do
    IO.write("#{@service.port()}> ")

    if run_command(IO.gets("")), do: looper()
  end

  @doc false
  @spec run_command(binary() | :eof) :: boolean()
  def run_command(input)
  def run_command(:eof), do: do_run_command("quit")
  def run_command(cmd), do: do_run_command(String.trim(cmd))

  @spec do_run_command(binary()) :: boolean()
  defp do_run_command(command)
  defp do_run_command(""), do: :ok

  defp do_run_command("help") do
    """
    Available commands are:
      help   Displays this help message
      build  Rebuilds the project
      quit   Stops the server and quit
    """
    |> IO.write()

    true
  end

  defp do_run_command("build") do
    @service.rebuild()

    true
  end

  defp do_run_command("quit") do
    site_dir = @service.site_dir()

    IO.puts("Removing temporary directory \"#{site_dir}\"...")
    File.rm_rf!(site_dir)
    IO.puts("Shutting down...")

    false
  end

  defp do_run_command(_) do
    warn("Type \"help\" for the list of available commands.")

    true
  end
end
