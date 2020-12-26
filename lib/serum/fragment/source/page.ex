defimpl Serum.Fragment.Source, for: Serum.V2.Page do
  require Serum.V2.Result, as: Result
  alias Serum.Renderer
  alias Serum.Template.Storage, as: TS
  alias Serum.V2.Fragment
  alias Serum.V2.Page

  @spec to_fragment(Page.t()) :: Result.t(Fragment.t())
  def to_fragment(page) do
    template_name = page.template || "page"
    bindings = [page: page, contents: page.data]

    Result.run do
      template <- TS.get(template_name, :template)
      html <- Renderer.render_fragment(template, bindings)

      Serum.Fragment.new(page.source, page.dest, page, html)
    end
  end
end
