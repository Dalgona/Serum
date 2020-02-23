defmodule Serum.V2.PostList do
  @moduledoc """
  A struct containing information about a (maybe paginated) list of blog posts.

  ## Fields

  - `dest` - the path on the file system which the complete HTML page for the
    blog post list will be written to.
  - `tag` - a `Serum.V2.Tag` struct, or `nil` if the list lists all posts.
  - `current_page` - number of the current page.
  - `last_page` - number of the last page.
  - `title` - title of the blog post list.
  - `posts` - a list of blog post information.
  - `url` - absolute URL of the post list page in the website.
  - `extras` - a map for arbitrary key-value data associated with the post list.
  """

  alias Serum.V2.Tag

  @type t :: %__MODULE__{
          tag: Tag.t() | nil,
          current_page: pos_integer(),
          last_page: pos_integer(),
          title: binary(),
          posts: [map()],
          url: binary(),
          dest: binary(),
          extras: map()
        }

  defstruct ~w(tag current_page last_page title posts url dest extras)a
end
