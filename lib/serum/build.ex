defmodule Serum.Build do
  @moduledoc """
  This module contains functions for generating pages of your website.
  """

  import Serum.Util
  alias Serum.Error
  alias Serum.Validation
  alias Serum.Build.{PageBuilder, PostBuilder, IndexBuilder, Renderer}

  @type build_mode :: :parallel | :sequential
  @type compiled_template :: tuple

  @spec build(String.t, String.t, build_mode) :: Error.result(String.t)
  def build(src, dest, mode) do
    src = String.ends_with?(src, "/") && src || src <> "/"
    dest = dest || src <> "site/"
    dest = String.ends_with?(dest, "/") && dest || dest <> "/"

    case check_access dest do
      :ok -> do_build_stage1 src, dest, mode
      err -> {:error, :file_error, {err, dest, 0}}
    end
  end

  @spec check_access(String.t) :: :ok | File.posix
  defp check_access(dest) do
    parent = dest |> String.replace_suffix("/", "") |> :filename.dirname
    case File.stat parent do
      {:error, reason} -> reason
      {:ok, %File.Stat{access: :none}} -> :eacces
      {:ok, %File.Stat{access: :read}} -> :eacces
      {:ok, _} -> :ok
    end
  end

  @spec do_build_stage1(String.t, String.t, build_mode)
    :: Error.result(String.t)
  defp do_build_stage1(src, dest, mode) do
    IO.puts "Rebuilding Website..."
    Serum.init_data
    Serum.put_data "pages_file", []

    clean_dest dest
    prep_results =
      [load_info(src), load_templates(src), scan_pages(src, dest)]
      |> Error.filter_results(:build_preparation)
    case prep_results do
      :ok -> do_build_stage2 src, dest, mode
      error -> error
    end
  end

  @spec do_build_stage2(String.t, String.t, build_mode)
    :: Error.result(String.t)
  defp do_build_stage2(src, dest, mode) do
    {time, result} =
      :timer.tc fn ->
        compile_nav
        launch_tasks mode, src, dest
      end
    case result do
      :ok ->
        IO.puts "Build process took #{time/1000}ms."
        copy_assets src, dest
        {:ok, dest}
      error -> error
    end
  end

  @spec load_info(String.t) :: Error.result
  def load_info(dir) do
    path = dir <> "serum.json"
    IO.puts "Reading project metadata `#{path}`..."
    case File.read path do
      {:ok, data} ->
        do_load_info path, data
      {:error, reason} ->
        {:error, :file_error, {reason, "#{dir}serum.json", 0}}
    end
  end

  @spec do_load_info(String.t, String.t) :: Error.result
  defp do_load_info(path, data) do
    case Poison.decode data do
      {:ok, proj} ->
        do_validate proj
      {:error, :invalid} ->
        {:error, :json_error, {:invalid_json, path, 0}}
      {:error, {:invalid, token}} ->
        {:error, :json_error, {"parse error near `#{token}`", path, 0}}
    end
  end

  @spec do_validate(map) :: Error.result
  defp do_validate(proj) do
    Validation.load_schema
    case Validation.validate "serum.json", proj do
      :ok ->
        Enum.each proj, fn {k, v} -> Serum.put_data "proj", k, v end
        check_date_format
        check_list_title_format
        :ok
      error -> error
    end
  end

  @spec check_date_format() :: :ok
  def check_date_format do
    fmt = Serum.get_data "proj", "date_format"
    if fmt != nil do
      case Timex.format Timex.now, fmt do
        {:ok, _} -> :ok
        {:error, _} ->
          warn "Invalid date format string `date_format`."
          warn "The default format string will be used instead."
          Serum.del_data "proj", "date_format"
      end
    end
  end

  @spec check_list_title_format() :: :ok
  def check_list_title_format do
    fmt = Serum.get_data "proj", "list_title_tag"
    try do
      if fmt != nil do
        fmt |> :io_lib.format(["test"]) |> IO.iodata_to_binary
      end
    rescue
      _e in ArgumentError ->
        warn "Invalid post list title format string `list_title_tag`."
        warn "The default format string will be used instead."
        Serum.del_data "proj", "list_title_tag"
    end
  end

  @spec load_templates(String.t) :: Error.result
  defp load_templates(dir) do
    IO.puts "Loading templates..."
    ["base", "list", "page", "post", "nav"]
    |> Enum.map(&do_load_templates(dir, &1))
    |> Error.filter_results(:load_templates)
  end

  @spec do_load_templates(String.t, String.t) :: Error.result
  defp do_load_templates(dir, name) do
    path = "#{dir}templates/#{name}.html.eex"
    case File.read path do
      {:ok, data} ->
        try do
          template_str = "<% import Serum.TemplateHelper %>" <> data
          ast = EEx.compile_string template_str
          Serum.put_data "template", name, ast
          :ok
        rescue
          e in EEx.SyntaxError ->
            {:error, :invalid_template, {e.message, path, e.line}}
          e in SyntaxError ->
            {:error, :invalid_template, {e.description, path, e.line}}
        end
      {:error, reason} ->
        {:error, :file_error, {reason, path, 0}}
    end
  end

  @spec scan_pages(String.t, String.t) :: Error.result
  defp scan_pages(src, dest) do
    dir = src <> "pages/"
    IO.puts "Scanning `#{dir}` directory..."
    if File.exists?(dir), do: do_scan_pages(dir, src, dest),
    else: {:error, :file_error, {:enoent, dir, 0}}
  end

  @spec do_scan_pages(String.t, String.t, String.t) :: :ok
  defp do_scan_pages(path, src, dest) do
    path
    |> File.ls!
    |> Enum.each(fn x ->
      f = Regex.replace ~r(/+), "#{path}/#{x}", "/"
      cond do
        File.dir? f ->
          f |> String.replace_prefix("#{src}pages/", dest) |> File.mkdir_p!
          do_scan_pages f, src, dest
        String.ends_with?(f, ".md") or String.ends_with?(f, ".html") ->
          Serum.put_data "pages_file", [f|Serum.get_data "pages_file"]
        :otherwise -> :skip
      end
    end)
  end

  @spec clean_dest(String.t) :: :ok
  defp clean_dest(dest) do
    File.mkdir_p! "#{dest}"
    IO.puts "Created directory `#{dest}`."

    # exclude dotfiles so that git repository is not blown away
    dest |> File.ls!
         |> Enum.filter(&(not String.starts_with?(&1, ".")))
         |> Enum.map(&("#{dest}#{&1}"))
         |> Enum.each(&File.rm_rf!(&1))
  end

  @spec launch_tasks(build_mode, String.t, String.t) :: Error.result
  defp launch_tasks(:parallel, src, dest) do
    IO.puts "⚡️  \x1b[1mStarting parallel build...\x1b[0m"
    t1 = Task.async fn -> PageBuilder.run src, dest, :parallel end
    t2 = Task.async fn -> PostBuilder.run src, dest, :parallel end
    results = [Task.await(t1), Task.await(t2)]
    # IndexBuilder must be run after PostBuilder has finished
    t3 = Task.async fn -> IndexBuilder.run src, dest, :parallel end
    results = results ++ [Task.await t3]
    Error.filter_results results, :launch_tasks
  end

  defp launch_tasks(:sequential, src, dest) do
    IO.puts "⌛️  \x1b[1mStarting sequential build...\x1b[0m"
    r1 = PageBuilder.run src, dest, :sequential
    r2 = PostBuilder.run src, dest, :sequential
    r3 = IndexBuilder.run src, dest, :sequential
    results = [r1, r2, r3]
    Error.filter_results results, :launch_tasks
  end

  @spec compile_nav() :: :ok
  defp compile_nav do
    IO.puts "Compiling main navigation HTML stub..."
    template = Serum.get_data "template", "nav"
    html = Renderer.render template, []
    Serum.put_data "navstub", html
  end

  @spec copy_assets(String.t, String.t) :: :ok
  defp copy_assets(src, dest) do
    IO.puts "Copying assets and media..."
    try_copy "#{src}assets/", "#{dest}assets/"
    try_copy "#{src}media/", "#{dest}media/"
  end

  @spec try_copy(String.t, String.t) :: :ok
  defp try_copy(src, dest) do
    case File.cp_r src, dest do
      {:error, reason, _} ->
        warn "Cannot copy #{src}: #{:file.format_error(reason)}. Skipping."
      {:ok, _} -> :ok
    end
  end
end
