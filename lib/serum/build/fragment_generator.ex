defmodule Serum.Build.FragmentGenerator do
  @moduledoc false

  _moduledocp = "Renders page/post/post list structs into a page fragment."

  import Serum.IOProxy, only: [put_msg: 2]
  alias Serum.Error
  alias Serum.Fragment
  alias Serum.Plugin.Client, as: PluginClient
  alias Serum.Result

  @spec to_fragment(map()) :: Result.t([Fragment.t()])
  def to_fragment(map) do
    put_msg(:info, "Generating fragments...")

    map
    |> Map.take([:pages, :posts, :lists])
    |> Enum.map(&elem(&1, 1))
    |> List.flatten()
    |> Task.async_stream(&task_fun(&1))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate_values("failed to generate HTML fragments:")
  end

  @spec task_fun(struct()) :: Result.t(Fragment.t())
  defp task_fun(fragment_source) do
    case Fragment.Source.to_fragment(fragment_source) do
      {:ok, fragment} -> PluginClient.rendered_fragment(fragment)
      {:error, %Error{}} = error -> error
    end
  end
end
