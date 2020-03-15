defmodule Serum.Template.Compiler do
  @moduledoc false

  _moduledocp = "This module handles template loading and preprocessing."

  require Serum.V2.Result, as: Result
  alias Serum.Error
  alias Serum.Plugin.Client, as: PluginClient
  alias Serum.Template
  alias Serum.V2

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

    files
    |> Task.async_stream(&compile_file(&1, options))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate("failed to compile EEx templates:")
    |> case do
      {:ok, list} -> Result.return(Map.new(list))
      {:error, %Error{}} = error -> error
    end
  end

  @spec compile_file(V2.File.t(), options()) :: Result.t({binary(), Template.t()})
  defp compile_file(file, options) do
    Result.run do
      file2 <- PluginClient.processing_template(file)
      ast <- compile_string(file2.in_data, file2)
      name = Path.basename(file2.src, ".html.eex")
      template = Template.new(ast, name, options[:type], file2)
      template2 <- PluginClient.processed_template(template)

      Result.return({name, template2})
    end
  end

  @doc "Compiles the given EEx string."
  @spec compile_string(binary(), V2.File.t(), keyword()) :: Result.t(Macro.t())
  def compile_string(string, %V2.File{src: src} = file, options \\ []) do
    options = Keyword.put(options, :file, src)

    {:ok, {:__block__, [], [@inject, EEx.compile_string(string, options)]}}
  rescue
    e in [SyntaxError, TokenMissingError, EEx.SyntaxError] ->
      Result.fail(Exception: [e, __STACKTRACE__], file: file, line: e.line)
  end
end
