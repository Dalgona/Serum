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

    bd_args  = [fn -> %{} end, [name: Serum.BuildData]]
    pis_args = [fn -> [] end,  [name: Serum.PostInfoStorage]]

    children = [
      worker(Agent, bd_args, id: "serum_bd"),
      worker(Agent, pis_args, id: "serum_pis")
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
  @spec put_data(key :: String.t, value :: any) :: :ok
  def put_data(key, value) do
    Agent.update(Serum.BuildData, &(Map.put &1, key, value))
  end

  @doc """
  This function is identical to `put_data(path <> "__" <> key, value)`.
  """
  @spec put_data(path :: String.t, key :: String.t, value :: any) :: :ok
  def put_data(path, key, value) do
    Agent.update(Serum.BuildData, &(Map.put &1, "#{path}__#{key}", value))
  end

  @doc """
  Trys to get a value with key `key` from `Serum.BuildData` agent.
  """
  @spec get_data(key :: String.t) :: any | nil
  def get_data(key) do
    Agent.get(Serum.BuildData, &(Map.get &1, key))
  end

  @doc """
  This function is identical to `get_data(path <> "__" <> key)`.
  """
  @spec get_data(path :: String.t, key :: String.t) :: any | nil
  def get_data(path, key) do
    Agent.get(Serum.BuildData, &(Map.get &1, "#{path}__#{key}"))
  end

  @doc """
  Trys to remove a value with key `key` from `Serum.BuildData` agent.
  """
  @spec del_data(key :: String.t) :: :ok
  def del_data(key) do
    Agent.update(Serum.BuildData, &(Map.delete &1, key))
  end

  @doc """
  This function is identical to `del_data(path <> "__" <> key)`.
  """
  @spec del_data(path :: String.t, key :: String.t) :: :ok
  def del_data(path, key) do
    Agent.update(Serum.BuildData, &(Map.delete &1, "#{path}__#{key}"))
  end
end

