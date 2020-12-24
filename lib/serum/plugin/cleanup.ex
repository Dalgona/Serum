defmodule Serum.Plugin.Cleanup do
  @moduledoc false

  _moduledocp = """
  Provides functions for cleaning up loaded plugins and unload them.
  """

  require Serum.ForeignCode, as: ForeignCode
  require Serum.V2.Result, as: Result
  import Serum.V2.Console
  alias Serum.Error.Format
  alias Serum.Plugin
  alias Serum.Plugin.State
  alias Serum.V2.Error

  @spec cleanup() :: Result.t({})
  def cleanup do
    Enum.each(Plugin.states(), &cleanup_each/1)
    Agent.update(Plugin, fn _ -> %State{} end)
    Result.return()
  end

  @spec cleanup_each({module(), term()}) :: Result.t({})
  defp cleanup_each({module, state}) do
    case do_cleanup_each(module, state) do
      {:ok, _} ->
        Result.return()

      {:error, %Error{} = error} ->
        {:error, warn} =
          Result.fail("an error occurred while cleaning up a plugin", caused_by: [error])

        put_err(:warn, Format.format_text(warn, 0))
    end
  end

  @spec do_cleanup_each(module(), term()) :: Result.t({})
  defp do_cleanup_each(module, state) do
    ForeignCode.call module.cleanup(state) do
      _ -> Result.return()
    end
  end
end
