defmodule Serum.BuildPass1.IndexBuilder do
  alias Serum.Build
  alias Serum.Error
  alias Serum.Tag

  @type state :: Build.state

  @spec run(Build.mode, state) :: Error.result(Tag.t)

  def run(mode, _state) do
    tags =
      state.build_data["post_info"]
      |> Enum.reduce(MapSet.new(), fn info, acc ->
        MapSet.union acc, MapSet.new(info.tags)
      end)
      |> MapSet.to_list
    {:ok, tags}
  end
end
