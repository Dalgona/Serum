defmodule Serum do
  use Application
  alias Serum.GlobalBindings
  alias Serum.Template

  @moduledoc """
  Defines Serum OTP application.
  """

  @doc """
  Starts the `Serum` application.

  This starts a supervisor and an Agent as its child process, which stores a
  JSON schema for `serum.json` file.
  """
  def start(_type, _args) do
    children = [
      Template,
      GlobalBindings
    ]
    opts = [strategy: :one_for_one, name: Serum.Supervisor]
    {:ok, _pid} = Supervisor.start_link children, opts
  end
end
