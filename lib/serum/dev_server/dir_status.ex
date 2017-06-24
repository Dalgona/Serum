defmodule Serum.DevServer.DirStatus do
  @moduledoc """
  A GenServer which holds a boolean flag indicating whether changes are detected
  in the source directory since the last check.
  """

  use GenServer

  # Client

  @doc "Starts `Serum.DevServer.DirStatus` GenServer."
  @spec start_link() :: {:ok, pid}

  def start_link, do: GenServer.start_link __MODULE__, false, name: __MODULE__

  @doc "Checks if the source directory is marked as dirty."
  @spec dirty?() :: boolean

  def dirty?, do: GenServer.call __MODULE__, :is_dirty

  @doc "Set the source directory as dirty."
  @spec set_dirty() :: :ok

  def set_dirty, do: GenServer.cast __MODULE__, :set_dirty

  # Server (callbacks)

  @doc false

  def handle_call(msg, from, state)

  def handle_call(:is_dirty, _from, state), do: {:reply, state, false}

  @doc false

  def handle_cast(msg, state);

  def handle_cast(:set_dirty, _state), do: {:noreply, true}
end
