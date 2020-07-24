defmodule Serum.V2.Project.BlogConfiguration do
  @moduledoc """
  A struct containing configuration for a blog.

  ## Fields

  - `source_dir` - the path to a directory relative to the project root, which
    contains source files of blog posts. Defaults to `"posts"`.
  - `posts_path` - Path in an output directory which your rendered blog posts
    will be written to. Defaults to the value of `:posts_source`. (The default
    value will be `"posts"` if `:posts_source` is not explicitly given.)
  - `tags_path` - Path in an output directory which the tag pages will be
    written to. Defaults to `"tags"`.
  - `list_title_all` - title of the list of all posts. Defaults to `"All Posts"`.
  - `list_title_tag` - text format of the title of tag-filtered post lists.
    Exactly one `~s` must be present in the format, as this is the placeholder
    for tag name. If you need to display `~` in the list title, insert `~~`
    (two consecutive tildes). Defaults to `"Posts Tagged ~s"`.
  - `pagination` - sets whether the post list will be split into multiple pages.
    If set to `true`, each list page will have at most `posts_per_page` entries.
    Defaults to `true`.
  - `posts_per_page` - the number of blog post entries per page in a list. This
    configuration has no effect if `pagination` is set to false. Defaults to 10.
  - `list_template` - name of the default template which will be used to render
    post lists. Defaults to `"list"`.
  - `post_template` - name of the default template which will be used to render
    blog posts. Defaults to `"post"`.
  """

  @type t :: %__MODULE__{
          source_dir: binary(),
          posts_path: binary(),
          tags_path: binary(),
          list_title_all: binary(),
          list_title_tag: binary(),
          pagination: boolean(),
          posts_per_page: boolean(),
          list_template: binary(),
          post_template: binary()
        }

  defstruct source_dir: "posts",
            posts_path: "posts",
            tags_path: "tags",
            list_title_all: "All Posts",
            list_title_tag: "Posts Tagged ~s",
            pagination: true,
            posts_per_page: 10,
            list_template: "list",
            post_template: "post"
end
