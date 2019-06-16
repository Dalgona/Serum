defmodule Serum.DevServer.Logger do
  @moduledoc false

  @behaviour Microscope.Callback

  alias Serum.IOProxy

  def on_request, do: nil
  def on_200(from, method, path), do: log(200, from, method, path)
  def on_404(from, method, path), do: log(404, from, method, path)

  defp log(status, from, method, path) do
    msg =
      [
        [status_color(status), "[", to_string(status), "] ", :reset],
        [from, ?\s, method, ?\s, :bright, path]
      ]
      |> IO.ANSI.format()
      |> IO.iodata_to_binary()

    IOProxy.put_msg(:info, msg)
  end

  defp status_color(code)
  defp status_color(code) when code in 200..299, do: :green
  defp status_color(code) when code in 400..499, do: :red
end
