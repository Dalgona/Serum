defmodule Serum.Build.FileProcessor.Template do
  @moduledoc false

  import Serum.IOProxy, only: [put_msg: 2]
  alias Serum.Result
  alias Serum.Template.Compiler, as: TC

  @doc false
  @spec compile_templates(map()) :: Result.t({map(), map()})
  def compile_templates(%{templates: templates, includes: includes}) do
    put_msg(:info, "Compiling templates...")

    with {:ok, includes} <- TC.compile_files(includes, type: :include),
         tc_options = [type: :template, includes: includes],
         {:ok, templates} <- TC.compile_files(templates, tc_options) do
      {:ok, {templates, includes}}
    else
      {:error, _} = error -> error
    end
  end
end
