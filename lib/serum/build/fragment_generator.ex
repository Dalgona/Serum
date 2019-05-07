defmodule Serum.Build.FragmentGenerator do
  @moduledoc """
  Renders page/post/post list structs into a page fragment.
  """

  alias Serum.Fragment
  alias Serum.Result

  @spec to_fragment(map()) :: Result.t([Fragment.t()])
  def to_fragment(map) do
    IO.puts("Generating fragments...")

    templates = map.templates

    map
    |> Map.take([:pages, :posts, :lists])
    |> Enum.map(fn {_, v} ->
      Task.async(fn -> task_fun(v, templates) end)
    end)
    |> Enum.map(&Task.await/1)
    |> Result.aggregate_values(:fragment_generator)
    |> case do
      {:ok, results} -> {:ok, List.flatten(results)}
      {:error, _} = error -> error
    end
  end

  @spec task_fun([struct()], map()) :: Result.t([Fragment.t()])
  defp task_fun(items, templates) do
    items
    |> Task.async_stream(&Fragment.Source.to_fragment(&1, templates))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate_values(:fragment_generator)
  end
end
