defmodule Serum do
  use Application
  alias Serum.Validation

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
      supervisor(Registry, [:unique, Serum.Registry]),
      worker(Agent, [fn -> %{} end, [name: Serum.Schema]])
    ]
    opts = [strategy: :one_for_one, name: Serum.Supervisor]
    {:ok, pid} = Supervisor.start_link children, opts
    Validation.load_schema()
    {:ok, pid}
  end
end
