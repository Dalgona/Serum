defmodule Serum.DevServer.LiveReloadHandler do
  @moduledoc false

  @behaviour :cowboy_websocket

  require Serum.Util
  import Serum.Util
  alias Serum.DevServer.Service

  @impl true
  def init(req, state) do
    {:cowboy_websocket, req, state, %{idle_timeout: :infinity}}
  end

  @impl true
  def websocket_init(state) do
    warn("Live Reloader: WebSocket connected.")
    FileSystem.subscribe(Service.fs_watcher())

    {:ok, state}
  end

  @impl true
  def websocket_handle(message, state) do
    warn("Live Reloader: Ignoring a message from client: #{inspect(message)}")

    {:ok, state}
  end

  @impl true
  def websocket_info(message, state)

  def websocket_info({:file_event, _pid, {path, _events}}, state) do
    ignore? =
      path
      |> Path.relative_to(Service.source_dir())
      |> Path.split()
      |> Enum.any?(&dotfile?/1)

    if ignore? do
      {:ok, state}
    else
      {:reply, {:text, "reload"}, state}
    end
  end

  def websocket_info({:file_event, _pid, :stop}, state) do
    {:ok, state}
  end

  @impl true
  def terminate(reason, _mini_req, _state) do
    warn("Live Reloader: WebSocket disconnected: #{inspect(reason)}")

    :ok
  end

  @spec dotfile?(binary()) :: boolean()
  defp dotfile?(item)
  defp dotfile?(<<?.::8, _::binary>>), do: true
  defp dotfile?(_), do: false
end
