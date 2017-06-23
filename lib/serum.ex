defmodule Serum do
  use Application
  alias Serum.Validation

  @moduledoc """
  Defines Serum OTP application.
  """

  @doc """
  Starts the `Serum` application.

  This starts a supervisor and an Agent as its child process, which stores a
  JSON schema for `serum.json` file.
  """
  def start(_type, _args) do
    import Supervisor.Spec
    children = [
      worker(Agent, [fn -> %{} end, [name: Serum.Schema]])
    ]
    opts = [strategy: :one_for_one, name: Serum.Supervisor]
    {:ok, pid} = Supervisor.start_link children, opts
    Validation.load_schema()
    {:ok, pid}
  end
end
