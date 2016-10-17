defmodule Serum do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(Agent, [fn -> %{} end, [name: Serum.BuildData]])
    ]

    opts = [strategy: :one_for_one, name: Serum.Supervisor]

    {:ok, _pid} = Supervisor.start_link children, opts
  end

  def init_data() do
    Agent.update Serum.BuildData, fn _ -> %{} end
    :ok
  end

  def put_data(key, value) do
    Agent.update Serum.BuildData, &(Map.put &1, key, value)
    :ok
  end

  def get_data(key) do
    Agent.get Serum.BuildData, &(Map.get &1, key)
  end
end
