defmodule Serum.DevServer do
  @moduledoc """
  This module provides functions for starting the Serum development server.
  """

  alias Serum.Error
  alias Serum.DevServer.{Service, AutoBuilder, Looper}
  alias Serum.SiteBuilder

  @doc """
  Starts the Serum development server.

  This function starts a supervisor and required child processes and starts
  infinite command prompt loop.

  The website is built under a subdirectory of `/tmp` directory, and will be
  deleted when the server is stopped.
  """
  @spec run(dir :: binary, port :: pos_integer) :: any

  def run(dir, port) do
    import Supervisor.Spec

    uniq = Base.url_encode64 <<System.monotonic_time::size(64)>>, padding: false
    site = "/tmp/serum_" <> uniq

    {:ok, pid_builder} = SiteBuilder.start_link dir, site
    case SiteBuilder.load_info pid_builder do
      {:error, _} = error -> Error.show error
      {:ok, proj} ->
        base = proj.base_url
        ms_callbacks = [Microscope.Logger, AutoBuilder]
        ms_options   = [port: port, base: base, callbacks: ms_callbacks]
        children = [
          worker(Service, [pid_builder, dir, site, port]),
          worker(__MODULE__, [dir], function: :start_watcher, id: "serum_fs"),
          worker(Microscope, [site, ms_options]),
        ]
        opts = [strategy: :one_for_one, name: Serum.DevServer.Supervisor]
        Supervisor.start_link children, opts
        Looper.looper()
    end
  end

  @doc false
  @spec start_watcher(binary) :: {:ok, pid}

  def start_watcher(dir) do
    dir = Path.absname dir
    pid = spawn_link fn ->
      :fs.start_link :watcher, dir
      :fs.subscribe :watcher
      watcher_looper()
    end
    {:ok, pid}
  end

  defp watcher_looper() do
    receive do
      {_pid, {:fs, :file_event}, {_path, _events}} ->
        Service.set_dirty()
        watcher_looper()
      _ ->
        watcher_looper()
    end
  end
end
