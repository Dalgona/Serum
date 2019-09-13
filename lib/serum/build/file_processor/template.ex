defmodule Serum.Build.FileProcessor.Template do
  @moduledoc false

  import Serum.IOProxy, only: [put_msg: 2]
  alias Serum.Result
  alias Serum.Template
  alias Serum.Template.Compiler, as: TC
  alias Serum.Template.Storage, as: TS

  @type compile_result :: %{optional(binary()) => Template.t()}
  @typep type :: Template.template_type()

  # TODO: The return type will be `Result.t()`.
  @spec compile_templates(map()) :: Result.t({map(), map()})
  def compile_templates(%{templates: template_files, includes: include_files}) do
    put_msg(:info, "Compiling and loading templates...")

    with {:ok, includes} <- compile_and_load(include_files, :include),
         {:ok, templates} <- compile_and_load(template_files, :template) do
      {:ok, {templates, includes}}
    else
      {:error, _} = error -> error
    end
  end

  # TODO: The return type will be `Result.t()`.
  @spec compile_and_load([Serum.File.t()], type()) :: Result.t(compile_result())
  defp compile_and_load(files, type) do
    case TC.compile_files(files, type: type) do
      {:ok, result} ->
        TS.load(result, type)

        # TODO: Remove this line after finishing the implementation.
        {:ok, result}

      {:error, _} = error ->
        error
    end
  end
end
