defmodule Serum.PostInfo do
  @moduledoc "This module defines PostInfo struct."

  alias Serum.Build

  @type t :: %Serum.PostInfo{}
  @type state :: Build.state

  defstruct [:file, :title, :date, :raw_date, :tags, :url, :preview_text, :html]

  @doc "A helper function for creating a new PostInfo struct."
  @spec new(binary, Build.header, Build.erl_datetime, binary, state) :: t

  def new(filename, header, raw_date, html, state) do
    base = state.project_info.base_url
    date_fmt = state.project_info.date_format
    {title, tags} = header
    date_str =
      raw_date
      |> Timex.to_datetime(:local)
      |> Timex.format!(date_fmt)
    url =
      filename
      |> String.replace_prefix(state.src, "")
      |> String.replace_suffix("md", "html")
    %Serum.PostInfo{
      file: filename,
      title: title,
      tags: tags,
      html: html,
      preview_text: make_preview(html, state.project_info.preview_length),
      raw_date: raw_date,
      date: date_str,
      url: base <> url
    }
  end

  @spec make_preview(binary, non_neg_integer) :: binary

  def make_preview(html, maxlen) do
    case maxlen do
      0 -> ""
      x when is_integer(x) ->
        parsed =
          case Floki.parse html do
            t when is_tuple(t) -> [t]
            l when is_list(l)  -> l
          end
        parsed
        |> Enum.filter_map(&(elem(&1, 0) == "p"), &Floki.text/1)
        |> Enum.join(" ")
        |> String.slice(0, x)
    end
  end
end

defimpl Inspect, for: Serum.PostInfo do
  def inspect(info, _opts), do: ~s(#Serum.PostInfo<"#{info.title}">)
end
