defmodule Serum.DevServer.Prompt do
  @moduledoc """
  Provides access to the Serum development server command line interface.
  """

  import Serum.Util
  alias Serum.DevServer.Service

  @type options :: [allow_detach: boolean()]
  @type result :: {:ok, :detached} | {:ok, :quitted} | {:error, :noproc}

  @service Application.get_env(:serum, :service, Service.GenServer)

  @doc """
  Tries to start a Serum development server command line interface.

  This function first checks if the server is already running. If the server
  is not running, this function returns `{:error, :noproc}` immediately.
  Otherwise, it starts a loop which processes commands from the user. If the
  user runs the `detach` command, the loop completes and this function returns
  `{:ok, :detached}` tuple. If the user runs the `quit` command, the Serum
  development server will be stopped, and then this function will return
  `{:ok, :quitted}` tuple.

  ## Options

  - `allow_detach`: Controls if users are allowed to detach the command line
    interface. Defaults to `true`.
  """
  @spec start(options()) :: result()
  def start(options \\ []) do
    with pid when is_pid(pid) <- Process.whereis(@service),
         true <- Process.alive?(pid) do
      options2 = Map.merge(%{allow_detach: true}, Map.new(options))

      looper(options2)
    else
      _ -> {:error, :noproc}
    end
  end

  @spec looper(map()) :: result()
  defp looper(options) do
    IO.write("#{@service.port()}> ")

    case run_command(IO.gets(""), options) do
      :quit -> {:ok, :quitted}
      :detach -> {:ok, :detached}
      :ok -> looper(options)
    end
  end

  @doc false
  @spec run_command(binary() | :eof, map()) :: :ok | :detach | :quit
  def run_command(input, options)
  def run_command(:eof, options), do: do_run_command("quit", options)
  def run_command(cmd, options), do: do_run_command(String.trim(cmd), options)

  @spec do_run_command(binary(), map()) :: :ok | :detach | :quit
  defp do_run_command(command, options)
  defp do_run_command("", _options), do: :ok

  defp do_run_command("help", %{allow_detach: false}) do
    """
    Available commands are:
      help   Displays this help message
      build  Rebuilds the project
      quit   Stops the server and quit
    """
    |> IO.write()

    :ok
  end

  defp do_run_command("help", %{allow_detach: true}) do
    """
    Available commands are:
      help    Displays this help message
      build   Rebuilds the project
      detach  Detaches from this command line interface
              while keeping the Serum development server running
      quit    Stops the server and quit
    """
    |> IO.write()

    :ok
  end

  defp do_run_command("build", _options) do
    @service.rebuild()

    :ok
  end

  defp do_run_command("detach", %{allow_detach: false}) do
    warn("You cannot detach from this command line interface.")
    warn("Run \"quit\" to stop the server and quit.")

    :ok
  end

  defp do_run_command("detach", %{allow_detach: true}) do
    :detach
  end

  defp do_run_command("quit", _options) do
    Supervisor.stop(Serum.DevServer.Supervisor)

    :quit
  end

  defp do_run_command(_, _options) do
    warn("Type \"help\" for the list of available commands.")

    :ok
  end
end
