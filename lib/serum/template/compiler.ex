defmodule Serum.Template.Compiler do
  @moduledoc false

  _moduledocp = "This module handles template loading and preprocessing."

  alias Serum.Plugin
  alias Serum.Result
  alias Serum.Template
  alias Serum.Template.Compiler.Include

  @type options :: [type: Template.type()]

  @default_options [type: :template]

  @inject """
  <%
  require Serum.Template.Helpers
  import Serum.Template.Helpers
  %>
  """

  @doc """
  Compiles a list of template files.

  A code that requires and imports `Serum.Template.Helpers` is injected before
  the input data.

  The `files` parameter is a list of `Serum.File` structs representing loaded
  template files. That is, for each item of this list, the value of `:in_data`
  must not be `nil`.

  The `options` parameter is a keyword list of additional options controlling
  the behavior of this function. The available options are:

  - `type`: Either `:template` or `:include`, defaults to `:template`.
  """
  @spec compile_files([Serum.File.t()], options()) :: Result.t(Template.collection())
  def compile_files(files, options) do
    options = Keyword.merge(@default_options, options)

    result =
      files
      |> Task.async_stream(&compile_file(&1, options))
      |> Enum.map(&elem(&1, 1))
      |> Result.aggregate_values(:template_loader)

    case result do
      {:ok, list} -> {:ok, Map.new(list)}
      {:error, _} = error -> error
    end
  end

  @spec compile_file(Serum.File.t(), options()) :: Result.t({binary(), Template.t()})
  defp compile_file(file, options) do
    injected_file = %Serum.File{file | in_data: @inject <> file.in_data}

    with {:ok, file2} <- Plugin.processing_template(injected_file),
         {:ok, ast} <- compile_string(file2.in_data, options),
         template = Template.new(ast, options[:type], file2.src),
         name = Path.basename(file2.src, ".html.eex"),
         {:ok, template2} <- Plugin.processed_template(template) do
      {:ok, {name, template2}}
    else
      {:ct_error, msg, line} -> {:error, {msg, file.src, line}}
      {:error, _} = plugin_error -> plugin_error
    end
  end

  @doc """
  Compiles the given EEx string.
  """
  @spec compile_string(binary(), options()) ::
          {:ok, Macro.t()}
          | {:ct_error, binary(), integer()}
  def compile_string(string, options) do
    compiled = EEx.compile_string(string)

    case options[:type] do
      :include -> {:ok, compiled}
      _ -> Include.expand(compiled)
    end
  rescue
    e in EEx.SyntaxError ->
      {:ct_error, e.message, e.line}

    e in [SyntaxError, TokenMissingError] ->
      {:ct_error, e.description, e.line}
  end
end
