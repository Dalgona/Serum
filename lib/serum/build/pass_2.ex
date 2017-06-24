defmodule Serum.Build.Pass2 do
  @moduledoc """
  This module takes care of the second pass of site building process.

  In pass 2, the following modules are run sequentially or parallelly. See the
  docs for each module for more information.

  * `Serum.Build.Pass2.PageBuilder`
  * `Serum.Build.Pass2.PostBuilder`
  * `Serum.Build.Pass2.IndexBuilder`
  """

  alias Serum.Build
  alias Serum.Build.Pass2.PageBuilder
  alias Serum.Build.Pass2.PostBuilder
  alias Serum.Build.Pass2.IndexBuilder
  alias Serum.Error

  @doc "Starts the second pass of the building process in given build mode."
  @spec run(Build.mode, Build.state) :: Error.result

  def run(build_mode, state)

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
