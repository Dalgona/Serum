defmodule Serum.DevServer do
  @moduledoc """
  This module provides functions for starting the Serum development server.
  """

  alias Serum.DevServer.DirStatus
  alias Serum.DevServer.Service
  alias Serum.DevServer.AutoBuilder

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
      %{base_url: base} = "#{dir}serum.json"
                          |> File.read!
                          |> Poison.decode!(keys: :atoms)

      ms_callbacks = [Microscope.Logger, AutoBuilder]
      children = [
        worker(DirStatus, []),
        worker(__MODULE__, [dir], function: :start_watcher, id: "devserver_fs"),
        worker(Microscope, [site, base, port, ms_callbacks]),
        worker(Serum.DevServer.Service, [dir, site, port]),
        worker(Serum.DevServer.Looper, [])
      ]

      opts = [strategy: :one_for_one, name: Serum.DevServer.Supervisor]
      Supervisor.start_link children, opts

      Service.rebuild

      looper
    end
  end

  @spec start_watcher(String.t) :: {:ok, pid}
  def start_watcher(dir) do
    dir = :filename.absname dir
    pid = spawn_link fn ->
      :fs.start_link :watcher, dir
      :fs.subscribe :watcher
      watcher_looper
    end
    {:ok, pid}
  end

  defp watcher_looper() do
    receive do
      {_pid, {:fs, :file_event}, {_path, _events}} ->
        DirStatus.set_dirty
        watcher_looper
      _ ->
        watcher_looper
    end
  end

  defp looper, do: looper
end
