defmodule Serum.DevServer.DirStatus do
  @moduledoc """
  A GenServer which holds a boolean flag indicating whether changes are detected
  in the source directory since the last check.
  """

  use GenServer

  # Client

  @spec start_link() :: {:ok, pid}
  def start_link, do: GenServer.start_link __MODULE__, false, name: __MODULE__

  @spec dirty?() :: boolean
  def dirty?, do: GenServer.call __MODULE__, :is_dirty

  @spec set_dirty() :: :ok
  def set_dirty, do: GenServer.cast __MODULE__, :set_dirty

  # Server (callbacks)

  def handle_call(:is_dirty, _from, state), do: {:reply, state, false}

  def handle_cast(:set_dirty, _state), do: {:noreply, true}
end
