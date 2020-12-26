defmodule Serum.V2.Fragment do
  @moduledoc """
  A struct containing information about a page fragment.

  A page fragment is a portion of a HTML document which contents is to be
  inserted into the `base.html.eex` template to make a full HTML page.

  ## Fields

  - `source`: a `Serum.V2.File` struct holding the source file information, or
    `nil` if the fragment is created from scratch by Serum or plugins.
  - `dest` - the path on the file system which the complete HTML page for the
    fragment will be written to.
  - `metadata` - a struct or a map holding extra information about the fragment.
  - `data` - contents of the page fragment.
  """

  alias Serum.V2
  alias Serum.V2.Page
  alias Serum.V2.Post
  alias Serum.V2.PostList

  @type t :: %__MODULE__{
          source: V2.File.t(),
          dest: binary(),
          metadata: Page.t() | Post.t() | PostList.t() | map(),
          data: binary()
        }

  defstruct [:source, :dest, :metadata, :data]
end
