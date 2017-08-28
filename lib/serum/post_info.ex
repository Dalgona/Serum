defmodule Serum.PostInfo do
  @moduledoc "This module defines PostInfo struct."

  alias Serum.Build
  alias Serum.Tag

  @type t :: %Serum.PostInfo{}
  @type state :: Build.state

  defstruct [
    :file, :title, :date, :raw_date, :tags,
    :url, :preview_text, :html, :output
  ]

  @doc "A helper function for creating a new PostInfo struct."
  @spec new(binary, map, binary, state) :: t

  def new(filename, header, html, state) do
    base = state.project_info.base_url
    date_fmt = state.project_info.date_format
    title = header.title
    tags =
      header
      |> Map.get(:tags, [])
      |> Enum.sort
      |> Enum.map(&%Tag{name: &1, list_url: "#{base}tags/#{&1}/index.html"})
    datetime = header[:date] || Timex.to_datetime(Timex.zero(), :local)
    date_str = Timex.format! datetime, date_fmt
    raw_date = datetime |> Timex.to_erl
    relname =
      filename
      |> String.replace_suffix("md", "html")
      |> Path.relative_to(state.src)
    %Serum.PostInfo{
      file: filename,
      title: title,
      tags: tags,
      html: html,
      preview_text: make_preview(html, state.project_info.preview_length),
      raw_date: raw_date,
      date: date_str,
      url: Path.join(base, relname),
      output: Path.join(state.dest, relname)
    }
  end

  @spec make_preview(binary, non_neg_integer) :: binary

  defp make_preview(html, maxlen) do
    case maxlen do
      0 -> ""
      x when is_integer(x) ->
        parsed =
          case Floki.parse html do
            t when is_tuple(t) -> [t]
            l when is_list(l)  -> l
          end
        parsed
        |> Enum.filter(&elem(&1, 0) == "p")
        |> Enum.map(&Floki.text/1)
        |> Enum.join(" ")
        |> String.slice(0, x)
    end
  end
end

defimpl Inspect, for: Serum.PostInfo do
  def inspect(info, _opts), do: ~s(#Serum.PostInfo<"#{info.title}">)
end
