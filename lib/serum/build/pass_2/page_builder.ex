defmodule Serum.Build.Pass2.PageBuilder do
  alias Serum.Result
  alias Serum.Fragment
  alias Serum.Page

  @spec run([Page.t()], map()) :: Result.t([Fragment.t()])
  def run(pages, proj) do
    pages
    |> Task.async_stream(Page, :to_fragment, [proj])
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate_values(:page_builder)
  end
end
