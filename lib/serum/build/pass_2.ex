defmodule Serum.Build.Pass2 do
  alias Serum.Build
  alias Serum.Build.Pass2.PageBuilder
  alias Serum.Build.Pass2.PostBuilder
  alias Serum.Build.Pass2.IndexBuilder
  alias Serum.Error

  @spec run(Build.mode, Build.state) :: Error.result

  def run(:parallel, state) do
    [PageBuilder, PostBuilder, IndexBuilder]
    |> Enum.map(&Task.async(&1, :run, [:parallel, state]))
    |> Enum.map(&Task.await/1)
    |> Error.filter_results(:build_pass2)
  end

  def run(:sequential, state) do
    [PageBuilder, PostBuilder, IndexBuilder]
    |> Enum.map(& &1.run(:sequential, state))
    |> Error.filter_results(:build_pass2)
  end
end
