defimpl Serum.Fragment.Source, for: Serum.Post do
  require Serum.V2.Result, as: Result
  alias Serum.Fragment
  alias Serum.Post
  alias Serum.Renderer
  alias Serum.Template.Storage, as: TS

  @spec to_fragment(Post.t()) :: Result.t(Fragment.t())
  def to_fragment(post) do
    metadata = Post.compact(post)
    template_name = post.template || "post"
    bindings = [page: metadata, contents: post.data]

    Result.run do
      template <- TS.get(template_name, :template)
      html <- Renderer.render_fragment(template, bindings)

      Fragment.new(post.file, post.output, metadata, html)
    end
  end
end
