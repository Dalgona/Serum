defmodule Serum.Postinfo do
  @moduledoc "This module defines Postinfo struct."

  @type t :: %Serum.Postinfo{}

  defstruct [:file, :title, :date, :tags, :url, :preview_text]
end

defmodule Serum.Tag do
  @moduledoc "This module defines Tag struct."

  @type t :: %Serum.Tag{}

  defstruct [:name, :list_url]
end

defimpl Inspect, for: Serum.Tag do
  def inspect(tag, _opts), do: ~s(#Serum.Tag<"#{tag.name}": "#{tag.list_url}">)
end
