defmodule Serum.Project.Loader do
  @moduledoc false

  _moduledocp = "A module for loading Serum project definition files."

  require Serum.V2.Result, as: Result
  alias Serum.GlobalBindings
  alias Serum.StructValidator.BlogConfiguration, as: BlogValidator
  alias Serum.StructValidator.Project, as: ProjectValidator
  alias Serum.V2
  alias Serum.V2.Project

  @doc """
  Detects and loads Serum project configuration file from the source directory.
  """
  @spec load(binary()) :: Result.t(Project.t())
  def load(src) do
    Result.run do
      file <- V2.File.read(%V2.File{src: Path.join(src, "serum.exs")})
      value <- eval_file(file)
      ProjectValidator.validate(value)
      BlogValidator.validate(value.blog)
      project = Serum.Project.new(value)
      :ok = GlobalBindings.put(:project, project)

      Result.return(project)
    end
  end

  @spec eval_file(V2.File.t()) :: Result.t(term())
  defp eval_file(file) do
    file.in_data
    |> Code.eval_string([], file: file.src)
    |> elem(0)
    |> Result.return()
  rescue
    e in [CompileError, SyntaxError, TokenMissingError] ->
      Result.fail(Exception: [e, __STACKTRACE__], file: file, line: e.line)

    e ->
      Result.fail(Exception: [e, __STACKTRACE__], file: file)
  end
end
