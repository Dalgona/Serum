defmodule Serum.PostInfo do
  @moduledoc "This module defines PostInfo struct."

  alias Serum.Build

  @type t :: %Serum.PostInfo{}

  @default_date_format    "{YYYY}-{0M}-{0D}"

  defstruct [:file, :title, :date, :raw_date, :tags, :url, :preview_text]

  @doc "A helper function for creating a new PostInfo struct."
  @spec new(String.t, Build.header, Build.erl_datetime, String.t)
    :: Serum.PostInfo.t

  def new(filename, header, raw_date, preview) do
    base = Serum.get_data "proj", "base_url"
    date_fmt = Serum.get_data("proj", "date_format") || @default_date_format
    {title, tags, _lines} = header
    date_str = raw_date |> Timex.to_datetime(:local) |> Timex.format!(date_fmt)
    %Serum.PostInfo{
      file: filename,
      title: title,
      tags: tags,
      preview_text: preview,
      raw_date: raw_date,
      date: date_str,
      url: base <> "posts/" <> filename <> ".html"
    }
  end
end

defimpl Inspect, for: Serum.PostInfo do
  def inspect(info, _opts), do: ~s(#Serum.PostInfo<"#{info.title}">)
end

defmodule Serum.Tag do
  @moduledoc "This module defines Tag struct."

  @type t :: %Serum.Tag{}

  defstruct [:name, :list_url]
end

defimpl Inspect, for: Serum.Tag do
  def inspect(tag, _opts), do: ~s(#Serum.Tag<"#{tag.name}": "#{tag.list_url}">)
end
