defmodule Serum.DevServer do
  @moduledoc """
  This module provides functions for starting the Serum development server.
  """

  alias Serum.Error
  alias Serum.Build.Preparation
  alias Serum.DevServer.{DirStatus, Service, AutoBuilder, Looper}

  @spec run(dir :: String.t, port :: pos_integer) :: any
  def run(dir, port) do
    import Supervisor.Spec

    dir = String.ends_with?(dir, "/") && dir || dir <> "/"
    uniq = Base.url_encode64 <<System.monotonic_time::size(64)>>, padding: false
    site = "/tmp/serum_" <> uniq

    if not File.exists? "#{dir}serum.json" do
      IO.puts "\x1b[31mError: `#{dir}serum.json` not found."
      IO.puts "Make sure you point at a valid Serum project directory.\x1b[0m"
    else
      case Preparation.load_info dir do
        :ok ->
          base = Serum.get_data "proj", "base_url"
          ms_callbacks = [Microscope.Logger, AutoBuilder]
          ms_options   = [port: port, base: base, callbacks: ms_callbacks]
          children = [
            worker(Service, [dir, site, port]),
            worker(DirStatus, []),
            worker(__MODULE__, [dir], function: :start_watcher, id: "serum_fs"),
            worker(Microscope, [site, ms_options]),
            worker(Looper, [])
          ]
          opts = [strategy: :one_for_one, name: Serum.DevServer.Supervisor]
          Supervisor.start_link children, opts
          looper()
        error ->
          Error.show error
      end
    end
  end

  @spec start_watcher(String.t) :: {:ok, pid}
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

  defp looper, do: looper()
end
