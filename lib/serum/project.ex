defmodule Serum.Project do
  @moduledoc """
  This module defines a struct for storing Serum project metadata.
  """

  import Serum.V2.Console, only: [put_err: 2]
  alias Serum.Plugin
  alias Serum.Theme

  @default_date_format "{YYYY}-{0M}-{0D}"
  @default_list_title_tag "Posts Tagged ~s"

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
            src: nil,
            dest: nil,
            plugins: [],
            theme: %Theme{module: nil}

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
          plugins: [Plugin.spec()],
          theme: Theme.t()
        }

  @spec default_date_format() :: binary()
  def default_date_format, do: @default_date_format

  @spec default_list_title_tag() :: binary()
  def default_list_title_tag, do: @default_list_title_tag

  @doc "A helper function for creating a new Project struct."
  @spec new(map) :: t
  def new(map) do
    checked_map =
      map
      |> check_date_format()
      |> check_list_title_format()

    struct(__MODULE__, checked_map)
  end

  @spec check_date_format(map) :: map
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

  @spec check_list_title_format(map) :: map
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
end
