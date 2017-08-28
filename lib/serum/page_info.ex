defmodule Serum.PageInfo do
  @moduledoc "This module defines PageInfo struct."

  alias Serum.Build

  @type t :: %Serum.PageInfo{}
  @type state :: Build.state

  defstruct [:file, :type, :title, :label, :group, :order, :url, :output]

  @doc "A helper function for creating a new PageInfo struct."
  @spec new(binary, map, state) :: t

  def new(filename, header, state) do
    type = get_type filename
    relname =
      filename
      |> Path.rootname(type)
      |> Path.relative_to(state.src <> "pages/")
      |> Kernel.<>(".html")
    %Serum.PageInfo{
      file: filename,
      type: type,
      title: header[:title],
      label: header[:label] || header[:title],
      group: header[:group],
      order: header[:order],
      url: state.project_info.base_url <> relname,
      output: state.dest <> relname
    }
  end

  @spec get_type(binary) :: binary

  defp get_type(filename) do
    case Path.extname filename do
      ".eex" ->
        filename
        |> Path.basename(".eex")
        |> Path.extname()
        |> Kernel.<>(".eex")
      ext -> ext
    end
  end
end

defimpl Inspect, for: Serum.PageInfo do
  def inspect(info, _opts), do: ~s(#Serum.PageInfo<"#{info.title}">)
end
