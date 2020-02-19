defmodule Serum.V2.Page do
  @moduledoc """
  A struct containing information about a single page.

  ## Fields

  - `source` - a `Serum.V2.File` struct holding the source file information.
  - `dest` - the path on the file system which the complete HTML page for the
    page will be written to.
  - `type` - type of the page, either `"html"` or `"md"`.
  - `title` - title of the page.
  - `label` - short label text of the page, which can be used instead of the
    page title in navigation areas.
  - `group` - name of a group which the page belongs to.
  - `order` - order of the page within its group.
  - `url` - absoute URL of the page in the website.
  - `data` - source or processed post contents. Used internally within Serum or
    Serum plugins.
  - `template` - name of a custom template for the blog post, or `nil`.
  - `extras` - a map for arbitrary key-value data associated with the blog post.
  """

  alias Serum.V2

  @type t :: %__MODULE__{
          source: V2.File.t(),
          dest: binary(),
          type: binary(),
          title: binary(),
          label: binary(),
          group: binary() | nil,
          order: integer(),
          url: binary(),
          data: binary(),
          template: binary() | nil,
          extras: map()
        }

  defstruct [
    :source,
    :dest,
    :type,
    :title,
    :label,
    :group,
    :order,
    :url,
    :data,
    :template,
    :extras
  ]
end
