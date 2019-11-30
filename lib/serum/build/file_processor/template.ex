defmodule Serum.Build.FileProcessor.Template do
  @moduledoc false

  require Serum.Result, as: Result
  import Serum.IOProxy, only: [put_msg: 2]
  alias Serum.Template
  alias Serum.Template.Compiler, as: TC
  alias Serum.Template.Storage, as: TS

  @spec compile_templates(map()) :: Result.t({})
  def compile_templates(%{templates: templates, includes: includes}) do
    put_msg(:info, "Compiling and loading templates...")

    with {:ok, _} <- compile_and_load(includes, :include),
         {:ok, _} <- compile_and_load(templates, :template) do
      Result.return()
    else
      {:error, _} = error -> error
    end
  end

  @spec compile_and_load([Serum.File.t()], Template.type()) :: Result.t([Template.t()])
  defp compile_and_load(files, type) do
    case TC.compile_files(files, type: type) do
      {:ok, result} ->
        TS.load(result, type)
        result |> Enum.map(&elem(&1, 1)) |> expand_includes()

      {:error, _} = error ->
        error
    end
  end

  @spec expand_includes([Template.t()]) :: Result.t([Template.t()])
  defp expand_includes(templates) do
    templates
    |> Enum.map(&TC.Include.expand/1)
    |> Result.aggregate_values("failed to expand includes:")
  end
end
