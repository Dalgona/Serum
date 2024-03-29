defmodule Serum.Project do
  @moduledoc """
  This module defines a struct for storing Serum project metadata.
  """

  import Serum.IOProxy, only: [put_err: 2]
  alias Serum.Plugin
  alias Serum.Theme

  @default_date_format "{YYYY}-{0M}-{0D}"
  @default_list_title_tag "Posts Tagged ~s"
  @default_posts_source "posts"

  defstruct site_name: "",
            site_description: "",
            server_root: "",
            base_url: "",
            author: "",
            author_email: "",
            date_format: @default_date_format,
            list_title_all: "All Posts",
            list_title_tag: @default_list_title_tag,
            pagination: false,
            posts_per_page: 5,
            preview_length: 200,
            posts_source: @default_posts_source,
            posts_path: @default_posts_source,
            tags_path: "tags",
            src: nil,
            dest: nil,
            plugins: [],
            theme: %Theme{module: nil},
            pretty_urls: false

  @type t :: %__MODULE__{
          src: binary(),
          dest: binary(),
          site_name: binary(),
          site_description: binary(),
          server_root: binary(),
          base_url: binary(),
          author: binary(),
          author_email: binary(),
          date_format: binary(),
          list_title_all: binary(),
          list_title_tag: binary(),
          pagination: boolean(),
          posts_per_page: pos_integer(),
          preview_length: non_neg_integer(),
          posts_source: binary(),
          posts_path: binary(),
          tags_path: binary(),
          plugins: [Plugin.plugin_spec()],
          theme: Theme.t(),
          pretty_urls: pretty_urls()
        }

  @typedoc """
  Accepted value for the `pretty_urls` option

  - `false` disables pretty URLs.
  - `true` is currently the same as `:posts`.
  - `:posts` enables pretty URLs only for blog posts.
  """
  @type pretty_urls() :: boolean() | :posts

  @spec default_date_format() :: binary()
  def default_date_format, do: @default_date_format

  @spec default_list_title_tag() :: binary()
  def default_list_title_tag, do: @default_list_title_tag

  @doc "Creates a new Project struct using the given `map`."
  @spec new(map()) :: t()
  def new(map) do
    checked_map =
      map
      |> check_date_format()
      |> check_list_title_format()
      |> set_default_posts_path()

    struct(__MODULE__, checked_map)
  end

  @spec check_date_format(map()) :: map()
  defp check_date_format(map) do
    case map[:date_format] do
      nil ->
        map

      fmt when is_binary(fmt) ->
        case Timex.validate_format(fmt) do
          :ok ->
            map

          {:error, message} ->
            msg = """
            Invalid date format string `date_format`:
              #{message}
            The default format string will be used instead.
            """

            put_err(:warn, String.trim(msg))
            Map.delete(map, :date_format)
        end
    end
  end

  @spec check_list_title_format(map()) :: map()
  defp check_list_title_format(map) do
    case map[:list_title_tag] do
      nil ->
        map

      fmt when is_binary(fmt) ->
        :io_lib.format(fmt, ["test"])
        map
    end
  rescue
    ArgumentError ->
      msg = """
      Invalid post list title format string `list_title_tag`.
      The default format string will be used instead.
      """

      put_err(:warn, String.trim(msg))
      Map.delete(map, :list_title_tag)
  end

  @spec set_default_posts_path(map()) :: map()
  defp set_default_posts_path(map) do
    case map[:posts_path] do
      posts_path when is_binary(posts_path) -> map
      _ -> Map.put(map, :posts_path, map[:posts_source] || @default_posts_source)
    end
  end
end
