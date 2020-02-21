defimpl Serum.Fragment.Source, for: Serum.Page do
  require Serum.V2.Result, as: Result
  alias Serum.Fragment
  alias Serum.Page
  alias Serum.Renderer
  alias Serum.Template.Storage, as: TS

  @spec to_fragment(Page.t()) :: Result.t(Fragment.t())
  def to_fragment(page) do
    metadata = Page.compact(page)
    template_name = page.template || "page"
    bindings = [page: metadata, contents: page.data]

    Result.run do
      template <- TS.get(template_name, :template)
      html <- Renderer.render_fragment(template, bindings)

      Fragment.new(page.file, page.output, metadata, html)
    end
  end
end
