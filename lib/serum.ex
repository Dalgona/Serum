defmodule Serum do
  use Application

  @moduledoc """
  This module contains a callback function for `Serum` application and some
  shortcut functions for accessing `Serum.BuildData` agent.
  """

  @doc """
  Starts the `Serum` application.

  This callback starts two agents under its supervision tree, which are:

  * `Serum.BuildData`: An agent with a map used to store miscellaneous data
      during site builds.
  * `Serum.PostInfoStorage`: An agent with a list used to store post metadata
      for building post index pages.
  """
  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(Agent, [fn -> %{} end, [name: Serum.BuildData]], id: "serum_bd"),
      worker(Agent, [fn -> [] end, [name: Serum.PostInfoStorage]], id: "serum_pis")
    ]

    opts = [strategy: :one_for_one, name: Serum.Supervisor]

    {:ok, _pid} = Supervisor.start_link children, opts
  end

  @doc """
  Initializes `Serum.BuildData` agent with an empty map.
  """
  @spec init_data() :: :ok
  def init_data(), do:
    Agent.update Serum.BuildData, fn _ -> %{} end

  @doc """
  Adds a key-value pair into `Serum.BuildData` agent.
  """
  @spec put_data(key :: any, value :: any) :: :ok
  def put_data(key, value), do:
    Agent.update Serum.BuildData, &(Map.put &1, key, value)

  @doc """
  Trys to get a value with key `key` from `Serum.BuildData` agent.
  """
  @spec get_data(key :: any) :: any | nil
  def get_data(key), do:
    Agent.get Serum.BuildData, &(Map.get &1, key)
end
