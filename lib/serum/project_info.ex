defmodule Serum.ProjectInfo do
  @moduledoc """
  This module defines a struct for storing Serum project metadata.
  """

  import Serum.Util
  alias Serum.Result
  alias Serum.Validation

  @accepted_keys [
    "site_name",
    "site_description",
    "base_url",
    "author",
    "author_email",
    "date_format",
    "preview_length",
    "list_title_all",
    "list_title_tag",
    "pagination",
    "posts_per_page"
  ]

  defstruct site_name: "",
            site_description: "",
            base_url: "",
            author: "",
            author_email: "",
            date_format: "{YYYY}-{0M}-{0D}",
            preview_length: 200,
            list_title_all: "All Posts",
            list_title_tag: "Posts Tagged ~s",
            pagination: false,
            posts_per_page: 5,
            src: nil,
            dest: nil

  @type t :: %__MODULE__{
          src: binary(),
          dest: binary(),
          site_name: binary(),
          site_description: binary(),
          base_url: binary(),
          author: binary(),
          author_email: binary(),
          date_format: binary(),
          preview_length: non_neg_integer(),
          list_title_all: binary(),
          list_title_tag: binary(),
          pagination: boolean(),
          posts_per_page: pos_integer()
        }

  @doc "A helper function for creating a new ProjectInfo struct."
  @spec new(map) :: t

  def new(map) do
    default = %__MODULE__{}
    map_checked = map |> check_date_format() |> check_list_title_format()

    map_new =
      for {k, v} <- map_checked, k in @accepted_keys, into: %{} do
        {String.to_atom(k), v}
      end

    Map.merge(default, map_new)
  end

  @doc """
  Loads a Serum project info from the given file `path`.
  """
  @spec load(binary(), binary()) :: Result.t(t())
  def load(src, dest) do
    path = Path.join(src, "serum.json")

    with {:ok, text} <- File.read(path),
         {:ok, json} <- Poison.decode(text),
         :ok <- Validation.validate("project_info", json, path) do
      proj = new(json)
      {:ok, %__MODULE__{proj | src: src, dest: dest}}
    else
      # From File.read/1:
      {:error, reason} when is_atom(reason) ->
        {:error, {reason, path, 0}}

      # From Poison.decode/1:
      {:error, :invalid, pos} ->
        {:error, {"parse error at position #{pos}", path, 0}}

      {:error, {:invalid, token, pos}} ->
        {:error, {"parse error near `#{token}' at position #{pos}", path, 0}}

      # From Validation.validate/3:
      {:error, _} = error ->
        error
    end
  end

  @spec check_date_format(map) :: map

  defp check_date_format(map) do
    case map["date_format"] do
      nil ->
        map

      fmt when is_binary(fmt) ->
        case Timex.validate_format(fmt) do
          :ok ->
            map

          {:error, message} ->
            warn("Invalid date format string `date_format`:")
            warn("  " <> message)
            warn("The default format string will be used instead.")
            Map.delete(map, "date_format")
        end
    end
  end

  @spec check_list_title_format(map) :: map

  defp check_list_title_format(map) do
    try do
      case map["list_title_tag"] do
        nil ->
          map

        fmt when is_binary(fmt) ->
          :io_lib.format(fmt, ["test"])
          map
      end
    rescue
      _e in ArgumentError ->
        warn("Invalid post list title format string `list_title_tag`.")
        warn("The default format string will be used instead.")
        Map.delete(map, "list_title_tag")
    end
  end
end
