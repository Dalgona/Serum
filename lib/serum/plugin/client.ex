defmodule Serum.Plugin.Client do
  @moduledoc false

  _moduledocp = "Provides functions to call callbacks of loaded plugins."

  # For interface/2 macro
  require Serum.Plugin.Client.Macros
  import Serum.Plugin.Client.Macros
  alias Serum.Fragment
  alias Serum.Page
  alias Serum.Post
  alias Serum.PostList
  alias Serum.Template
  alias Serum.Result

  interface :action, build_started(src :: binary(), dest :: binary()) :: Result.t({})
  interface :function, reading_pages(files :: [binary()]) :: Result.t([binary()])
  interface :function, reading_posts(files :: [binary()]) :: Result.t([binary()])
  interface :function, reading_templates(files :: [binary()]) :: Result.t([binary()])
  interface :function, processing_page(file :: Serum.File.t()) :: Result.t(Serum.File.t())
  interface :function, processing_post(file :: Serum.File.t()) :: Result.t(Serum.File.t())
  interface :function, processing_template(file :: Serum.File.t()) :: Result.t(Serum.File.t())
  interface :function, processed_page(page :: Page.t()) :: Result.t(Page.t())
  interface :function, processed_post(post :: Post.t()) :: Result.t(Post.t())
  interface :function, processed_template(template :: Template.t()) :: Result.t(Template.t())
  interface :function, processed_list(list :: PostList.t()) :: Result.t(PostList.t())
  interface :function, processed_pages(pages :: [Page.t()]) :: Result.t([Page.t()])
  interface :function, processed_posts(posts :: [Post.t()]) :: Result.t([Post.t()])

  interface :function,
            rendering_fragment(html :: Floki.html_tree(), metadata :: map()) ::
              Result.t(Floki.html_tree())

  interface :function, rendered_fragment(frag :: Fragment.t()) :: Result.t(Fragment.t())
  interface :function, rendered_page(file :: Serum.File.t()) :: Result.t(Serum.File.t())
  interface :action, wrote_file(file :: Serum.File.t()) :: Result.t({})
  interface :action, build_succeeded(src :: binary(), dest :: binary()) :: Result.t({})

  interface :action,
            build_failed(src :: binary(), dest :: binary(), result :: Result.t(term)) ::
              Result.t({})

  interface :action, finalizing(src :: binary(), dest :: binary()) :: Result.t({})

  @spec call_action(atom(), [term()]) :: Result.t({})
  defp call_action(name, args) do
    raise "not implemented"
  end

  @spec call_function(atom(), [term()]) :: Result.t({})
  def call_function(name, args) do
    raise "not implemented"
  end
end
