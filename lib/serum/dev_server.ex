defmodule Serum.DevServer do
  alias Serum.DevServer.DirStatus
  @moduledoc """
  This module provides functions for starting the Serum development server.
  """

  alias Serum.DevServer.Service

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
      DirStatus.start_link
      %{base_url: base} = "#{dir}serum.json"
                          |> File.read!
                          |> Poison.decode!(keys: :atoms)

      children = [
        worker(__MODULE__, [site, base, port], function: :start_server, id: "devserver_http"),
        worker(__MODULE__, [dir], function: :start_watcher, id: "devserver_fs"),
        worker(Serum.DevServer.Service, [dir, site, port]),
        worker(Serum.DevServer.Looper, [])
      ]

      opts = [strategy: :one_for_one, name: Serum.DevServer.Supervisor]
      Supervisor.start_link children, opts

      Service.ensure_started
      Service.rebuild

      looper
    end
  end

  @spec start_server(dir :: String.t, base :: String.t, port :: pos_integer) ::
    {:ok, pid}
  def start_server(dir, base, port) do
    routes = [
      {"/[...]", Serum.DevServer.Handler, [dir: dir, base: base]}
    ]
    dispatch = :cowboy_router.compile [{:_, routes}]
    opts = [port: port]
    env = [dispatch: dispatch]
    {:ok, pid} = :cowboy.start_http Serum.DevServer.Http, 100, opts, env: env
    {:ok, pid}
  end

  @spec start_watcher(String.t) :: {:ok, pid}
  def start_watcher(dir) do
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
