defmodule Serum.V2.Post do
  @moduledoc """
  A struct containing information about a single blog post.

  ## Fields

  - `source` - a `Serum.V2.File` struct holding the source file information.
  - `dest` - the path on the file system which the complete HTML page for the
    blog post will be written to.
  - `type` - type of the blog post, either `"html"` or `"md"`.
  - `title` - title of the blog post.
  - `date` - a `DateTime` struct for the date of posting.
  - `tags` - a list of `Serum.V2.Tag` structs which are tags of the blog post.
  - `url` - absoute URL of the blog post in the website.
  - `data` - source or processed post contents. Used internally within Serum or
    Serum plugins.
  - `template` - name of a custom template for the blog post, or `nil`.
  - `extras` - a map for arbitrary key-value data associated with the blog post.
  """

  alias Serum.V2
  alias Serum.V2.Tag

  @type t :: %__MODULE__{
          source: V2.File.t(),
          dest: Path.t(),
          type: binary(),
          title: binary(),
          date: DateTime.t(),
          tags: [Tag.t()],
          url: Path.t(),
          data: binary(),
          template: binary() | nil,
          extras: map()
        }

  defstruct [
    :source,
    :dest,
    :type,
    :title,
    :date,
    :tags,
    :url,
    :data,
    :template,
    :extras
  ]
end
