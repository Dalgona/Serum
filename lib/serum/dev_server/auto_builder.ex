defmodule Serum.DevServer.AutoBuilder do
  @moduledoc """
  A callback module for Microscope which automatically rebuilds the website
  when changes are detected in the source directory.
  """

  @behaviour Microscope.Callback

  import Serum.Util
  alias Serum.DevServer.Service

  @spec on_request() :: no_return

  def on_request do
    if Service.dirty?() do
      warn("Changes were detected in the source directory.")
      Service.rebuild()
    end
  end

  @spec on_200(binary, binary, binary) :: no_return

  def on_200(_, _, _), do: :ok

  @spec on_404(binary, binary, binary) :: no_return

  def on_404(_, _, _), do: :ok
end
