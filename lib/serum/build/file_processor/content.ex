defmodule Serum.Build.FileProcessor.Content do
  @moduledoc false

  _moduledocp = """
  Provides common logic for processing contents of pages and blog posts.

  - Markdown contents will be transformed into HTML documents.
  - HTML contents will be processed as EEx templates and then
    rendered into HTML documents.
  """

  require Serum.Result, as: Result
  alias Serum.Error
  alias Serum.Markdown
  alias Serum.Project
  alias Serum.Renderer
  alias Serum.Template
  alias Serum.Template.Compiler, as: TC

  @spec process_content(binary(), binary(), Project.t(), keyword()) :: Result.t(binary())
  def process_content(data, type, proj, options)

  def process_content(data, "md", proj, _options) do
    Result.return(Markdown.to_html(data, proj))
  end

  def process_content(data, "html", _proj, options) do
    src_line = options[:line] || 1
    file = options[:file]

    Result.run do
      ast <- TC.compile_string(data, line: src_line)
      template = Template.new(ast, file.src, :template, file)
      expanded_template <- TC.Include.expand(template)

      Renderer.render_fragment(expanded_template, [])
    else
      {:ct_error, msg, line} ->
        Result.fail(Simple, [msg], file: file, line: line)

      {:error, %Error{}} = error ->
        error
    end
  end
end
