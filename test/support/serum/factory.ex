defmodule Serum.Factory do
  @moduledoc false

  use ExMachina
  use Serum.Factory.Files
  use Serum.Factory.Pages
  use Serum.Factory.Posts
  use Serum.Factory.PostLists
  use Serum.Factory.Projects
  use Serum.Factory.Tags
end
