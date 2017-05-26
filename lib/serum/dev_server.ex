defmodule Serum.DevServer do
  @moduledoc """
  This module provides functions for starting the Serum development server.
  """

  alias Serum.Error
  alias Serum.DevServer.{DirStatus, Service, AutoBuilder, Looper}
  alias Serum.SiteBuilder

  @spec run(dir :: binary, port :: pos_integer) :: any
  def run(dir, port) do
    import Supervisor.Spec

    dir = String.ends_with?(dir, "/") && dir || dir <> "/"
    uniq = Base.url_encode64 <<System.monotonic_time::size(64)>>, padding: false
    site = "/tmp/serum_" <> uniq

    {:ok, pid_builder} = SiteBuilder.start_link dir, site
    case SiteBuilder.load_info pid_builder do
      {:error, _, _} = error -> Error.show error
      {:ok, proj} ->
        base = proj.base_url
        ms_callbacks = [Microscope.Logger, AutoBuilder]
        ms_options   = [port: port, base: base, callbacks: ms_callbacks]
        children = [
          worker(Service, [pid_builder, dir, site, port]),
          worker(DirStatus, []),
          worker(__MODULE__, [dir], function: :start_watcher, id: "serum_fs"),
          worker(Microscope, [site, ms_options]),
        ]
        opts = [strategy: :one_for_one, name: Serum.DevServer.Supervisor]
        Supervisor.start_link children, opts
        Looper.looper()
    end
  end

  @spec start_watcher(binary) :: {:ok, pid}
  def start_watcher(dir) do
    dir = :filename.absname dir
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
        DirStatus.set_dirty
        watcher_looper()
      _ ->
        watcher_looper()
    end
  end
end
