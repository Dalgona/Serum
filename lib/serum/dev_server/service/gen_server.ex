defmodule Serum.DevServer.Service.GenServer do
  @moduledoc false

  _moduledocp = """
  A GenServer-based implementation of `Serum.DevServer.Service` behaviour.
  """

  use GenServer
  require Serum.V2.Result, as: Result
  import Serum.V2.Console, only: [put_err: 2, put_msg: 2]
  alias Serum.Build
  alias Serum.DevServer.Service
  alias Serum.Project
  alias Serum.Project.Loader, as: ProjectLoader

  @behaviour Service

  @type start_arg() :: {binary(), binary(), pos_integer()}

  #
  # GenServer Implementation - Client
  #

  @doc "Starts the GenServer process."
  @spec start_link(start_arg()) :: {:ok, pid()} | {:error, atom()}
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl Service
  @spec rebuild() :: :ok
  def rebuild, do: GenServer.call(__MODULE__, :rebuild)

  @impl Service
  @spec source_dir() :: binary
  def source_dir, do: GenServer.call(__MODULE__, :source_dir)

  @impl Service
  @spec site_dir() :: binary
  def site_dir, do: GenServer.call(__MODULE__, :site_dir)

  @impl Service
  @spec port() :: pos_integer
  def port, do: GenServer.call(__MODULE__, :port)

  @impl Service
  @spec dirty?() :: boolean
  def dirty?, do: GenServer.call(__MODULE__, :is_dirty)

  @impl Service
  @spec subscribe() :: :ok
  def subscribe, do: GenServer.call(__MODULE__, :subscribe)

  #
  # GenServer Implementation - Server
  #

  @impl GenServer
  def init({dir, site, portnum}) do
    false = Process.flag(:trap_exit, true)

    watcher =
      case FileSystem.start_link(dirs: [Path.absname(dir)]) do
        {:ok, pid} -> pid
        :ignore -> nil
      end

    state = %{
      watcher: watcher,
      dir: dir,
      site: site,
      portnum: portnum,
      is_dirty: false,
      subscribers: %{}
    }

    do_rebuild(dir, site)
    unless(is_nil(watcher), do: FileSystem.subscribe(watcher))

    {:ok, state}
  end

  @impl GenServer
  def handle_call(msg, from, state)

  def handle_call(:rebuild, _from, state) do
    do_rebuild(state.dir, state.site)

    {:reply, :ok, state}
  end

  def handle_call(:source_dir, _from, state), do: {:reply, state.dir, state}
  def handle_call(:site_dir, _from, state), do: {:reply, state.site, state}
  def handle_call(:port, _from, state), do: {:reply, state.portnum, state}

  def handle_call(:is_dirty, _from, state),
    do: {:reply, state.is_dirty, %{state | is_dirty: false}}

  def handle_call(:subscribe, {caller, _}, state) do
    ref = Process.monitor(caller)
    state2 = %{state | subscribers: Map.put(state.subscribers, ref, caller)}

    {:reply, :ok, state2}
  end

  @impl GenServer
  def handle_info(msg, state)

  def handle_info({:file_event, _, _}, %{is_dirty: true} = state) do
    {:noreply, state}
  end

  def handle_info({:file_event, pid, :stop}, %{watcher: pid} = state) do
    {:noreply, state}
  end

  def handle_info({:file_event, pid, {path, _}}, %{watcher: pid} = state) do
    ignore? =
      path
      |> Path.relative_to(state.dir)
      |> Path.split()
      |> Enum.any?(&dotfile?/1)

    if ignore? do
      {:noreply, state}
    else
      server = self()

      spawn_link(fn ->
        receive do
        after
          200 ->
            send(server, :tick)
        end
      end)

      {:noreply, %{state | is_dirty: true}}
    end
  end

  def handle_info(:tick, state) do
    do_rebuild(state.dir, state.site)
    Enum.each(state.subscribers, fn {_, pid} -> send(pid, :send_reload) end)

    {:noreply, %{state | is_dirty: false}}
  end

  def handle_info({:DOWN, ref, :process, _, _}, state) do
    {:noreply, %{state | subscribers: Map.delete(state.subscribers, ref)}}
  end

  def handle_info({:EXIT, _pid, :normal}, state), do: {:noreply, state}

  @impl GenServer
  def terminate(_reason, %{site: site, watcher: watcher}) do
    put_msg(:info, "Removing temporary directory \"#{site}\"...")
    File.rm_rf!(site)
    put_msg(:info, "Shutting down...")
    unless(is_nil(watcher), do: Process.exit(watcher, :shutdown))
  end

  @spec do_rebuild(binary(), binary()) :: Result.t({})
  defp do_rebuild(src, dest) do
    with {:ok, %Project{} = proj} <- ProjectLoader.load(src, dest),
         {:ok, ^dest} <- Build.build(proj) do
      Result.return()
    else
      {:error, _} = error -> build_failed(error)
    end
  end

  @spec build_failed(Result.t({})) :: Result.t({})
  defp build_failed(error) do
    Serum.Result.show(error)
    put_err(:warn, "Error occurred while building the website.")
    put_err(:warn, "The website may not be displayed correctly.")
  end

  @spec dotfile?(binary()) :: boolean()
  defp dotfile?(item)
  defp dotfile?(<<?.::8, _::binary>>), do: true
  defp dotfile?(_), do: false
end
