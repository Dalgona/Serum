defmodule Serum.DevServer.CommandHandler do
  @moduledoc false

  _moduledocp = """
  Run some commands.
  """

  @doc "Open the url in a browser."
  @callback open_url(url :: binary()) :: :ok | :error
end
