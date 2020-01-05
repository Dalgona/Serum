defmodule Serum.DevServer.CommandHandler.Impl do
  @moduledoc false

  _moduledocp = """
  An implementation of `Serum.DevServer.CommandHandler` behaviour.
  """

  alias Serum.DevServer.CommandHandler

  @behaviour CommandHandler

  @impl CommandHandler
  @spec open_url(url :: binary()) :: :ok | :error
  def open_url(url) do
    open_command =
      case :os.type() do
        {:unix, :darwin} -> "open"
        {:unix, _} -> "xdg-open"
        {:win32, _} -> "start"
      end

    case System.find_executable(open_command) do
      nil ->
        :error

      _ ->
        try do
          System.cmd(open_command, [url])
          :ok
        rescue
          _ -> :error
        end
    end
  end
end
