defmodule Serum.PostInfo do
  @moduledoc "This module defines PostInfo struct."

  alias Serum.Build

  @type t :: %Serum.PostInfo{}
  @type state :: Build.state

  defstruct [:file, :title, :date, :raw_date, :tags, :url, :preview_text]

  @doc "A helper function for creating a new PostInfo struct."
  @spec new(binary, Build.header, Build.erl_datetime, binary, state) :: t

  def new(filename, header, raw_date, preview, state) do
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
      preview_text: preview,
      raw_date: raw_date,
      date: date_str,
      url: base <> url
    }
  end
end

defimpl Inspect, for: Serum.PostInfo do
  def inspect(info, _opts), do: ~s(#Serum.PostInfo<"#{info.title}">)
end
