defmodule Serum.Build.FragmentGenerator do
  @moduledoc """
  Renders page/post/post list structs into a page fragment.
  """

  alias Serum.Fragment
  alias Serum.Plugin
  alias Serum.Result

  @spec to_fragment(map()) :: Result.t([Fragment.t()])
  def to_fragment(map) do
    IO.puts("Generating fragments...")

    templates = map.templates

    map
    |> Map.take([:pages, :posts, :lists])
    |> Enum.map(&elem(&1, 1))
    |> List.flatten()
    |> Task.async_stream(&task_fun(&1, templates))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate_values(:fragment_generator)
  end

  @spec task_fun(struct(), map()) :: Result.t(Fragment.t())
  defp task_fun(fragment_source, templates) do
    case Fragment.Source.to_fragment(fragment_source, templates) do
      {:ok, fragment} -> Plugin.rendered_fragment(fragment)
      {:error, _} = error -> error
    end
  end
end
