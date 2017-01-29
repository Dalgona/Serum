defmodule Serum.PostInfo do
  @moduledoc "This module defines PostInfo struct."

  import Serum.Util
  alias Serum.Build
  alias Serum.Build.ProjectInfo

  @type t :: %Serum.PostInfo{}

  #
  # Struct and its Helper Functions
  #

  defstruct [:file, :title, :date, :raw_date, :tags, :url, :preview_text]

  @doc "A helper function for creating a new PostInfo struct."
  @spec new(String.t, Build.header, Build.erl_datetime, String.t)
    :: Serum.PostInfo.t

  def new(filename, header, raw_date, preview) do
    base = ProjectInfo.get owner(), :base_url
    date_fmt = ProjectInfo.get owner(), :date_format
    {title, tags, _lines} = header
    date_str =
      raw_date
      |> Timex.to_datetime(:local)
      |> Timex.format!(date_fmt)
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

  #
  # Agent Accessors
  #

  defmacro name(owner) do
    quote do
      {:via, Registry, {Serum.Registry, {:post_info, unquote(owner)}}}
    end
  end

  def start_link(owner) do
    Agent.start_link fn -> [] end, name: name(owner)
  end

  def init(owner) do
    Agent.update name(owner), fn _ -> [] end
  end

  def add(owner, info) do
    Agent.update name(owner), &([info|&1])
  end

  def all(owner) do
    posts = Agent.get name(owner), &(&1)
    Enum.sort_by posts, &(&1.file)
  end

  def stop(owner) do
    Agent.stop name(owner)
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
