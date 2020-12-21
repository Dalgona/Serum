defmodule Serum.Project do
  @moduledoc """
  This module defines a struct for storing Serum project metadata.
  """

  import Serum.V2.Console, only: [put_err: 2]
  alias Serum.V2.Project
  alias Serum.V2.Project.BlogConfiguration

  @doc """
  Creates a new `Serum.V2.Project` struct from the given map.

  The map is expected to be already validated using
  `Serum.StructValidator.Project.validate/1` and
  `Serum.StructValidator.BlogConfiguration.validate/1` functions.
  """

  @spec new(map()) :: Project.t()
  def new(%{base_url: base_url, blog: blog} = map) do
    new_map = %{
      map
      | base_url: URI.parse(base_url),
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
