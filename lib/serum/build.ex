defmodule Serum.Build do
  @moduledoc """
  This module contains functions for generating pages of your website.
  """

  alias Serum.Error
  alias Serum.Build.PageBuilder
  alias Serum.Build.PostBuilder
  alias Serum.Build.IndexBuilder
  alias Serum.Build.Renderer

  @type build_mode :: :parallel | :sequential
  @type compiled_template :: tuple

  # TODO: check the destination dir for write permission before doing
  #       any build subtasks
  @spec build(String.t, String.t, build_mode) :: Error.result
  def build(src, dest, mode) do
    src = String.ends_with?(src, "/") && src || src <> "/"
    dest = dest || src <> "site/"
    dest = String.ends_with?(dest, "/") && dest || dest <> "/"

    IO.puts "Rebuilding Website..."
    Serum.init_data

    try do
      load_info src
      load_templates src
      clean_dest dest

      {time, result} = :timer.tc(fn ->
        compile_nav
        launch_tasks mode, src, dest
      end)

      case result do
        :ok ->
          IO.puts "Build process took #{time/1000}ms."
          copy_assets src, dest
          {:ok, dest}
        error = {:error, _, _} -> error
      end
    rescue
      e in File.Error ->
        {:error, :file_error, {Exception.message(e), e.path, 0}}
      e in Serum.JsonError ->
        {:error, :invalid_json, {e.message, e.file, 0}}
      e in Serum.TemplateError ->
        {:error, :invalid_template, {e.message, e.file, e.line}}
    end
  end

  @spec load_info(String.t) :: :ok
  @raises [Serum.JsonError, File.Error]
  defp load_info(dir) do
    IO.puts "Reading project metadata `#{dir}serum.json`..."

    try do
      proj = "#{dir}serum.json"
             |> File.read!
             |> Poison.decode!(keys: :atoms)
             |> Map.to_list
      Serum.put_data :proj, proj
    rescue
      e in Poison.SyntaxError ->
        raise Serum.JsonError, message: e.message, file: "#{dir}serum.json"
    end

    try do
      pageinfo = "#{dir}pages/pages.json"
                 |> File.read!
                 |> Poison.decode!(as: [%Serum.Pageinfo{}])
      Serum.put_data :pageinfo, pageinfo
    rescue
      e in Poison.SyntaxError ->
        raise Serum.JsonError, message: e.message, file: "#{dir}pages/pages.json"
    end
  end

  @spec load_templates(String.t) :: :ok
  @raises [Serum.TemplateError, File.Error]
  defp load_templates(dir) do
    IO.puts "Loading templates..."
    try do
      ["base", "list", "page", "post", "nav"]
      |> Enum.each(fn x ->
        tree = EEx.compile_file("#{dir}templates/#{x}.html.eex")
        Serum.put_data "template_#{x}", tree
      end)
    rescue
      e in EEx.SyntaxError ->
        raise Serum.TemplateError, file: e.file, line: e.line, message: e.message
      e in SyntaxError ->
        raise Serum.TemplateError, file: e.file, line: e.line, message: e.description
    end
  end

  @spec clean_dest(String.t) :: :ok
  defp clean_dest(dest) do
    File.mkdir_p! "#{dest}"
    IO.puts "Created directory `#{dest}`."

    dest |> File.ls!
         |> Enum.map(&("#{dest}#{&1}"))
         |> Enum.each(&(File.rm_rf! &1))
  end

  @spec launch_tasks(build_mode, String.t, String.t) :: any
  defp launch_tasks(:parallel, src, dest) do
    IO.puts "⚡️  \x1b[1mStarting parallel build...\x1b[0m"
    t1 = Task.async fn -> PageBuilder.run src, dest, :parallel end
    t2 = Task.async fn -> PostBuilder.run src, dest, :parallel end
    results = [Task.await(t1), Task.await(t2)]
    # IndexBuilder must be run after PostBuilder has finished
    t3 = Task.async fn -> IndexBuilder.run src, dest, :parallel end
    results = results ++ [Task.await(t3)]
    Error.filter_results(results, :launch_tasks)
  end

  defp launch_tasks(:sequential, src, dest) do
    IO.puts "⌛️  \x1b[1mStarting sequential build...\x1b[0m"
    r1 = PageBuilder.run src, dest, :sequential
    r2 = PostBuilder.run src, dest, :sequential
    r3 = IndexBuilder.run src, dest, :sequential
    results = [r1, r2, r3]
    Error.filter_results(results, :launch_tasks)
  end

  @spec compile_nav() :: :ok
  defp compile_nav do
    proj = Serum.get_data :proj
    info = Serum.get_data :pageinfo
    IO.puts "Compiling main navigation HTML stub..."
    template = Serum.get_data "template_nav"
    html = Renderer.render template, proj ++ [pages: Enum.filter(info, &(&1.menu))]
    Serum.put_data(:navstub, html)
  end

  @spec copy_assets(String.t, String.t) :: :ok
  defp copy_assets(src, dest) do
    IO.puts "Copying assets and media..."
    case File.cp_r("#{src}assets/", "#{dest}assets/") do
      {:error, :enoent, _} -> IO.puts "\x1b[93mAssets directory not found. Skipping...\x1b[0m"
      {:ok, _} -> :ok
    end
    case File.cp_r("#{src}media/", "#{dest}media/") do
      {:error, :enoent, _} -> IO.puts "\x1b[93mMedia directory not found. Skipping...\x1b[0m"
      {:ok, _} -> :ok
    end
    :ok
  end
end
