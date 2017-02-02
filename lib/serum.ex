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
      supervisor(Registry, [:unique, Serum.Registry]),
      worker(Serum.BuildDataStorage, ["global"], id: "serum_bd"),
    ]

    opts = [strategy: :one_for_one, name: Serum.Supervisor]

    {:ok, _pid} = Supervisor.start_link children, opts
  end
end
