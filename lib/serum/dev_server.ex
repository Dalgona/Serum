defmodule Serum.DevServer do
  @moduledoc """
  The Serum development server.
  """

  alias Serum.DevServer.{Looper, Service}
  alias Serum.Project
  alias Serum.Project.Loader, as: ProjectLoader
  alias Serum.Result

  @doc """
  Starts the Serum development server.
  """
  @spec run(binary, pos_integer) :: no_return()
  def run(dir, port) do
    uniq = Base.url_encode64(:crypto.strong_rand_bytes(6))
    site = Path.expand("serum_" <> uniq, System.tmp_dir!())

    case ProjectLoader.load(dir, site) do
      {:error, _} = error ->
        Result.show(error)

      {:ok, %Project{} = proj} ->
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
          {Service.GenServer, {dir, site, port}},
          %{
            id: Microscope,
            start: {Microscope, :start_link, [site, ms_options]}
          }
        ]

        opts = [strategy: :one_for_one, name: Serum.DevServer.Supervisor]
        Supervisor.start_link(children, opts)
        Looper.looper()
    end
  end
end
