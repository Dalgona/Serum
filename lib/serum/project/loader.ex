defmodule Serum.Project.Loader do
  @moduledoc false

  _moduledocp = "A module for loading Serum project definition files."

  require Serum.V2.Result, as: Result
  import Serum.V2.Console, only: [put_err: 2]
  alias Serum.GlobalBindings
  alias Serum.StructValidator.BlogConfiguration, as: BlogValidator
  alias Serum.StructValidator.Project, as: ProjectValidator
  alias Serum.V2
  alias Serum.V2.Project
  alias Serum.V2.Project.BlogConfiguration

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
      project = make_project(value)
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
      Result.from_exception(e, file: file, line: e.line)

    e ->
      Result.from_exception(e, file: file)
  end

  @spec make_project(map()) :: Project.t()
  defp make_project(%{base_url: base_url, blog: blog} = map) do
    uri =
      Map.update!(URI.parse(base_url), :path, fn
        nil -> "/"
        path when is_binary(path) -> path
      end)

    new_map = %{
      map
      | base_url: uri,
        blog: make_blog(blog)
    }

    struct(Project, new_map)
  end

  @spec make_blog(map() | false) :: BlogConfiguration.t() | false
  defp make_blog(blog_map_or_false)
  defp make_blog(false), do: false

  defp make_blog(%{} = blog_map) do
    struct(BlogConfiguration, check_list_title_tag(blog_map))
  end

  @spec check_list_title_tag(map()) :: map()
  defp check_list_title_tag(%{} = blog_map) do
    case blog_map[:list_title_tag] do
      nil ->
        blog_map

      format when is_binary(format) ->
        :io_lib.format(format, ["test"])
        blog_map
    end
  rescue
    ArgumentError ->
      message = """
      Invalid post list title format string (`list_title_tag`).
      The default format string will be used instead.
      """

      put_err(:warn, String.trim(message))
      Map.delete(blog_map, :list_title_tag)
  end
end
