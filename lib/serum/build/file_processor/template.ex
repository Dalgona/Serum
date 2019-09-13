defmodule Serum.Build.FileProcessor.Template do
  @moduledoc false

  import Serum.IOProxy, only: [put_msg: 2]
  alias Serum.Result
  alias Serum.Template
  alias Serum.Template.Compiler, as: TC
  alias Serum.Template.Storage, as: TS

  @typep type :: Template.template_type()

  @spec compile_templates(map()) :: Result.t()
  def compile_templates(%{templates: templates, includes: includes}) do
    put_msg(:info, "Compiling and loading templates...")

    case compile_and_load(includes, :include) do
      :ok -> compile_and_load(templates, :template)
      {:error, _} = error -> error
    end
  end

  @spec compile_and_load([Serum.File.t()], type()) :: Result.t()
  defp compile_and_load(files, type) do
    case TC.compile_files(files, type: type) do
      {:ok, result} -> TS.load(result, type)
      {:error, _} = error -> error
    end
  end
end
