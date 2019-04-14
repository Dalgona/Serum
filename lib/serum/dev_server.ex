defmodule Serum.DevServer do
  @moduledoc "Starts and manages the Serum development server."

  alias Serum.DevServer.{Looper, Service}
  alias Serum.Result
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
        ms_callbacks = [Microscope.Logger]

        ms_options = [
          port: port,
          base: base,
          callbacks: ms_callbacks,
          index: true,
          extra_routes: [
            {"/serum_live_reloader", Serum.DevServer.LiveReloadHandler, nil}
          ]
        ]

        children = [
          worker(Service, [pid_builder, dir, site, port]),
          worker(Microscope, [site, ms_options])
        ]

        opts = [strategy: :one_for_one, name: Serum.DevServer.Supervisor]
        Supervisor.start_link(children, opts)
        Looper.looper()
    end
  end
end
