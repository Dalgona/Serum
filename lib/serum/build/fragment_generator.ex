defmodule Serum.Build.FragmentGenerator do
  @moduledoc """
  Renders page/post/post list structs into a page fragment.
  """

  alias Serum.Fragment
  alias Serum.Project
  alias Serum.Result

  @spec to_fragment(map(), map()) :: Result.t([Fragment.t()])
  def to_fragment(map, proj) do
    IO.puts("Generating fragments...")

    map
    |> Enum.map(fn {_, v} -> Task.async(fn -> task_fun(v, proj) end) end)
    |> Enum.map(&Task.await/1)
    |> Result.aggregate_values(:fragment_generator)
    |> case do
      {:ok, results} -> {:ok, List.flatten(results)}
      {:error, _} = error -> error
    end
  end

  @spec task_fun([struct()], Project.t()) :: Result.t([Fragment.t()])
  defp task_fun(items, proj) do
    items
    |> Task.async_stream(&Fragment.Source.to_fragment(&1, proj))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate_values(:fragment_generator)
  end
end
