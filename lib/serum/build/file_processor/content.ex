defmodule Serum.Build.FileProcessor.Content do
  @moduledoc false

  _moduledocp = """
  Provides common logic for processing contents of pages and blog posts.

  - Markdown contents will be transformed into HTML documents.
  - HTML contents will be processed as EEx templates and then
    rendered into HTML documents.
  """

  require Serum.V2.Result, as: Result
  alias Serum.Markdown
  alias Serum.Renderer
  alias Serum.Template
  alias Serum.Template.Compiler, as: TC
  alias Serum.V2.BuildContext

  @spec process_content(binary(), binary(), BuildContext.t(), keyword()) :: Result.t(binary())
  def process_content(data, type, context, options)

  def process_content(data, "md", context, _options) do
    Result.return(Markdown.to_html(data, context.project))
  end

  def process_content(data, "html", _context, options) do
    src_line = options[:line] || 1
    file = options[:file]

    Result.run do
      ast <- TC.compile_string(data, file, line: src_line)
      template = Template.new(ast, file.src, :template, file)
      expanded_template <- TC.Include.expand(template)

      Renderer.render_fragment(expanded_template, [])
    end
  end
end
