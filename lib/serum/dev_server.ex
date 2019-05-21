defmodule Serum.DevServer do
  @moduledoc """
  The Serum development server.
  """

  alias Serum.DevServer.Service
  alias Serum.Project
  alias Serum.Project.Loader, as: ProjectLoader
  alias Serum.Result

  @doc """
  Starts the Serum development server.

  This function returns `{:ok, pid}` on success where `pid` is a process ID of
  a supervision tree for the Serum development server.
  """
  @spec run(binary, pos_integer) :: Result.t(pid())
  def run(dir, port) do
    uniq = Base.url_encode64(:crypto.strong_rand_bytes(6))
    site = Path.expand("serum_" <> uniq, System.tmp_dir!())

    with {:ok, %Project{} = proj} <- ProjectLoader.load(dir, site),
         {:ok, pid} when is_pid(pid) <- do_run(dir, site, port, proj) do
      {:ok, pid}
    else
      {:error, {:shutdown, {:failed_to_start_child, _, :eaddrinuse}}} ->
        msg =
          "could not start the Serum development server. " <>
            "Make sure the port #{port} is not used by other applications"

        {:error, msg}

      {:error, {:shutdown, reason}} when not is_list(reason) ->
        msg = "could not start the Serum development server: #{inspect(reason)}"

        {:error, msg}

      {:error, _} = error ->
        error
    end
  end

  @spec do_run(binary(), binary(), integer(), Project.t()) :: Supervisor.on_start()
  defp do_run(dir, site, port, proj) do
    trap_exit = Process.flag(:trap_exit, true)
    base = proj.base_url

    ms_options = [
      port: port,
      base: base,
      callbacks: [Microscope.Logger],
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

    sup_opts = [strategy: :one_for_one, name: Serum.DevServer.Supervisor]
    start_result = Supervisor.start_link(children, sup_opts)

    Process.flag(:trap_exit, trap_exit)

    start_result
  end
end
