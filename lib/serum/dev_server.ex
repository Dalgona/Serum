defmodule Serum.DevServer do
  @moduledoc "Starts and manages the Serum development server."

  alias Serum.Result
  alias Serum.DevServer.{Service, AutoBuilder, Looper}
  alias Serum.SiteBuilder

  @spec run(binary, pos_integer) :: no_return()
  def run(dir, port) do
    import Supervisor.Spec

    uniq = Base.url_encode64(:crypto.strong_rand_bytes(6))
    site = "/tmp/serum_" <> uniq

    {:ok, pid_builder} = SiteBuilder.start_link(dir, site)

    case SiteBuilder.load_info(pid_builder) do
      {:error, _} = error ->
        Result.show(error)

      {:ok, proj} ->
        base = proj.base_url
        ms_callbacks = [Microscope.Logger, AutoBuilder]
        ms_options = [port: port, base: base, callbacks: ms_callbacks]

        children = [
          worker(Service, [pid_builder, dir, site, port]),
          worker(__MODULE__, [dir], function: :start_watcher, id: "serum_fs"),
          worker(Microscope, [site, ms_options])
        ]

        opts = [strategy: :one_for_one, name: Serum.DevServer.Supervisor]
        Supervisor.start_link(children, opts)
        Looper.looper()
    end
  end

  @doc false
  @spec start_watcher(binary) :: {:ok, pid}
  def start_watcher(dir) do
    dir = Path.absname(dir)

    pid =
      spawn_link(fn ->
        :fs.start_link(:watcher, dir)
        :fs.subscribe(:watcher)
        watcher_looper()
      end)

    {:ok, pid}
  end

  defp watcher_looper do
    receive do
      {_pid, {:fs, :file_event}, {_path, _events}} ->
        Service.set_dirty()
        watcher_looper()

      _ ->
        watcher_looper()
    end
  end
end
