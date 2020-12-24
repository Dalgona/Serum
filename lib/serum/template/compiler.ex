defmodule Serum.Template.Compiler do
  @moduledoc false

  _moduledocp = "This module handles template loading and preprocessing."

  require Serum.V2.Result, as: Result
  alias Serum.Plugin.Client, as: PluginClient
  alias Serum.V2
  alias Serum.V2.Template

  @type options :: [type: Template.type()]

  @default_options [type: :template]

  inject =
    quote do
      require Serum.Template.Helpers
      import Serum.Template.Helpers
    end

  @inject inject

  @doc """
  Compiles a list of template files.

  A code that requires and imports `Serum.Template.Helpers` is injected before
  the input data.

  The `files` parameter is a list of `Serum.V2.File` structs representing loaded
  template files. That is, for each item of this list, the value of `:in_data`
  must not be `nil`.

  The `options` parameter is a keyword list of additional options controlling
  the behavior of this function. The available options are:

  - `type`: Either `:template` or `:include`, defaults to `:template`.
  """
  @spec compile_files([V2.File.t()], options()) :: Result.t(Template.collection())
  def compile_files(files, options) do
    options = Keyword.merge(@default_options, options)

    Result.run do
      files <- PluginClient.processing_templates(files)
      templates <- do_compile_files(files, options)
      templates <- PluginClient.processed_templates(templates)

      templates
      |> Enum.map(&{&1.name, &1})
      |> Map.new()
      |> Result.return()
    end
  end

  @spec do_compile_files([V2.File.t()], options()) :: Result.t([Template.t()])
  defp do_compile_files(files, options) do
    files
    |> Task.async_stream(&compile_file(&1, options))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate("failed to compile EEx templates:")
  end

  @spec compile_file(V2.File.t(), options()) :: Result.t(Template.t())
  defp compile_file(file, options) do
    Result.run do
      ast <- compile_string(file.in_data, file)
      name = Path.basename(file.src, ".html.eex")
      template = Serum.Template.new(ast, name, options[:type], file)

      Result.return(template)
    end
  end

  @doc "Compiles the given EEx string."
  @spec compile_string(binary(), V2.File.t(), keyword()) :: Result.t(Macro.t())
  def compile_string(string, %V2.File{src: src} = file, options \\ []) do
    options = Keyword.put(options, :file, src)

    {:ok, {:__block__, [], [@inject, EEx.compile_string(string, options)]}}
  rescue
    e in [SyntaxError, TokenMissingError, EEx.SyntaxError] ->
      Result.from_exception(e, file: file, line: e.line)
  end
end
