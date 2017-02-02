defmodule Serum do
  use Application

  @moduledoc """
  Defines Serum OTP application.
  """

  @doc """
  Starts the `Serum` application.

  This callback starts a Registry under its supervision tree in order to keep
  child process information.
  """
  def start(_type, _args) do
    import Supervisor.Spec
    children = [
      supervisor(Registry, [:unique, Serum.Registry])
    ]
    opts = [strategy: :one_for_one, name: Serum.Supervisor]
    {:ok, _pid} = Supervisor.start_link children, opts
  end
end
