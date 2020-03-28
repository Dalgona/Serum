defmodule Serum.Build.FragmentGenerator do
  @moduledoc false

  _moduledocp = "Renders page/post/post list structs into a page fragment."

  import Serum.V2.Console, only: [put_msg: 2]
  alias Serum.Fragment.Source, as: FragmentSource
  alias Serum.Plugin.Client, as: PluginClient
  alias Serum.V2.Error
  alias Serum.V2.Fragment
  alias Serum.V2.Result

  @spec to_fragment(map()) :: Result.t([Fragment.t()])
  def to_fragment(map) do
    put_msg(:info, "Generating fragments...")

    map
    |> Map.take([:pages, :posts, :lists])
    |> Enum.map(&elem(&1, 1))
    |> List.flatten()
    |> Task.async_stream(&task_fun(&1))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate("failed to generate HTML fragments:")
  end

  @spec task_fun(struct()) :: Result.t(Fragment.t())
  defp task_fun(fragment_source) do
    case FragmentSource.to_fragment(fragment_source) do
      {:ok, fragment} -> PluginClient.generated_fragment(fragment)
      {:error, %Error{}} = error -> error
    end
  end
end
