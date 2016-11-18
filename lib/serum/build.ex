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
    Serum.put_data("pages_file", [])

    try do
      clean_dest(dest)
      load_info(src)
      load_templates(src)
      scan_pages(src, dest)

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
      e in Serum.ValidationError ->
        {:error, :invalid_json, {e.message, e.file, 0}}
    end
  end

  # TODO: Split validation codes
  @spec load_info(String.t) :: :ok
  @raises [Serum.JsonError, File.Error]
  defp load_info(dir) do
    IO.puts "Reading project metadata `#{dir}serum.json`..."

    try do
      proj = "#{dir}serum.json"
             |> File.read!
             |> Poison.decode!
      # validate preview_length
      if (x = Map.get(proj, "preview_length")) != nil do
        if not is_integer(x),
          do: raise Serum.ValidationError, message: "`preview_length` must be an integer value", file: "#{dir}serum.json"
      end
      # validate date_format
      if Map.get(proj, "date_format") != nil do
        Timex.format!(Timex.now, Map.get(proj, :date_format))
      end
      Enum.each(proj, fn {k, v} -> Serum.put_data("proj", k, v) end)
    rescue
      e in Poison.SyntaxError ->
        raise Serum.JsonError, message: e.message, file: "#{dir}serum.json"
      Timex.Format.FormatError ->
        raise Serum.ValidationError, message: "`date_format` is invalid", file: "#{dir}serum.json"
    end
  end

  @spec load_templates(String.t) :: :ok
  @raises [Serum.TemplateError, File.Error]
  defp load_templates(dir) do
    IO.puts "Loading templates..."
    try do
      ["base", "list", "page", "post", "nav"]
      |> Enum.each(fn x ->
        tstr =
          "<% import Serum.TemplateHelper %>"
          <> File.read!("#{dir}templates/#{x}.html.eex")
        tree = EEx.compile_string(tstr)
        Serum.put_data("template", x, tree)
      end)
    rescue
      e in EEx.SyntaxError ->
        raise Serum.TemplateError, file: e.file, line: e.line, message: e.message
      e in SyntaxError ->
        raise Serum.TemplateError, file: e.file, line: e.line, message: e.description
    end
  end

  @spec scan_pages(String.t, String.t) :: :ok
  @raises [File.Error]
  defp scan_pages(src, dest) do
    IO.puts "Scanning `#{src}pages` directory..."
    do_scan_pages("#{src}pages/", src, dest)
  end

  @spec do_scan_pages(String.t, String.t, String.t) :: :ok
  @raises [File.Error]
  defp do_scan_pages(path, src, dest) do
    path
    |> File.ls!
    |> Enum.each(fn x ->
      f = Regex.replace(~r(/+), "#{path}/#{x}", "/")
      cond do
        File.dir?(f) ->
          f |> String.replace_prefix("#{src}pages/", dest)
            |> File.mkdir_p!
          do_scan_pages(f, src, dest)
        String.ends_with?(f, ".md") or String.ends_with?(f, ".html") ->
          Serum.put_data("pages_file", [f|Serum.get_data("pages_file")])
        true -> :skip
      end
    end)
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
    IO.puts "Compiling main navigation HTML stub..."
    template = Serum.get_data("template", "nav")
    html = Renderer.render(template, [])
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

