defmodule Serum.Build do
  @moduledoc """
  This module contains functions for generating pages of your website.
  """

  alias Serum.Build.PageBuilder
  alias Serum.Build.PostBuilder
  alias Serum.Build.Renderer

  def build(src, dest, mode, display_done \\ false) do
    src = String.ends_with?(src, "/") && src || src <> "/"
    dest = dest || src <> "site/"
    dest = String.ends_with?(dest, "/") && dest || dest <> "/"

    if not File.exists?("#{src}serum.json") do
      IO.puts "\x1b[31mError: `#{src}serum.json` not found."
      IO.puts "Make sure you point at a valid Serum project directory.\x1b[0m"
      {:error, :no_project}
    else
      IO.puts "Rebuilding Website..."
      Serum.init_data

      load_info src
      load_templates src
      clean_dest dest

      {time, _} = :timer.tc(fn ->
        compile_nav
        launch_tasks mode, src, dest
      end)
      IO.puts "Build process took #{time}us."
      copy_assets src, dest

      if display_done do
        IO.puts ""
        IO.puts "\x1b[1mYour website is now ready to be served!"
        IO.puts "Copy(move) the contents of `#{dest}` directory"
        IO.puts "into your public webpages directory.\x1b[0m\n"
      end

      {:ok, dest}
    end
  end

  defp load_info(dir) do
    IO.puts "Reading project metadata `#{dir}serum.json`..."
    proj = "#{dir}serum.json"
           |> File.read!
           |> Poison.decode!(keys: :atoms)
           |> Map.to_list
    pageinfo = "#{dir}pages/pages.json"
               |> File.read!
               |> Poison.decode!(as: [%Serum.Pageinfo{}])
    Serum.put_data :proj, proj
    Serum.put_data :pageinfo, pageinfo
  end

  defp load_templates(dir) do
    IO.puts "Loading templates..."
    ["base", "list", "page", "post", "nav"]
    |> Enum.each(fn x ->
      tree = EEx.compile_file("#{dir}templates/#{x}.html.eex")
      Serum.put_data "template_#{x}", tree
    end)
  end

  defp clean_dest(dest) do
    File.mkdir_p! "#{dest}"
    IO.puts "Created directory `#{dest}`."

    dest |> File.ls!
         |> Enum.map(&("#{dest}#{&1}"))
         |> Enum.each(&(File.rm_rf! &1))
  end

  defp launch_tasks(:parallel, src, dest) do
    IO.puts "⚡️  \x1b[1mStarting parallel build...\x1b[0m"
    t1 = Task.async fn -> PageBuilder.run src, dest, :parallel end
    t2 = Task.async fn -> PostBuilder.run src, dest, :parallel end
    Task.await t1
    Task.await t2
  end

  defp launch_tasks(:sequential, src, dest) do
    IO.puts "⌛️  \x1b[1mStarting sequential build...\x1b[0m"
    PageBuilder.run src, dest, :sequential
    PostBuilder.run src, dest, :sequential
  end

  defp compile_nav do
    proj = Serum.get_data :proj
    info = Serum.get_data :pageinfo
    IO.puts "Compiling main navigation HTML stub..."
    template = Serum.get_data "template_nav"
    html = Renderer.render template, proj ++ [pages: Enum.filter(info, &(&1.menu))]
    Serum.put_data :navstub, html
  end

  defp copy_assets(src, dest) do
    IO.puts "Cleaning assets and media directories..."
    File.rm_rf! "#{dest}assets/"
    File.rm_rf! "#{dest}media/"
    IO.puts "Copying assets and media..."
    case File.cp_r("#{src}assets/", "#{dest}assets/") do
      {:error, :enoent, _} -> IO.puts "\x1b[93mAssets directory not found. Skipping...\x1b[0m"
      {:ok, _} -> :ok
    end
    case File.cp_r("#{src}media/", "#{dest}media/") do
      {:error, :enoent, _} -> IO.puts "\x1b[93mMedia directory not found. Skipping...\x1b[0m"
      {:ok, _} -> :ok
    end
  end
end
