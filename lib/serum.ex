defmodule Serum do
  @moduledoc """
  This module contains entry points for various serum tasks.
  """

  import Serum.Init
  import Serum.Build

  def init(dir) do
    dir = if String.ends_with?(dir, "/"), do: dir, else: dir <> "/"
    if File.exists? dir do
      IO.puts "Warning: The directory `#{dir}` " <>
              "already exists and might not be empty."
    end

    init :dir, dir
    init :infofile, dir
    init :page, dir
    init :templates, dir

    File.open! "#{dir}.gitignore", [:write, :utf8], fn f ->
      IO.write f, "site\n"
    end
    IO.puts "Generated `#{dir}.gitignore`."

    IO.puts "\nSuccessfully initialized a new Serum project!"
    IO.puts "try `serum build #{dir}` to build the site."
  end

  def build(dir) do
    dir = if String.ends_with?(dir, "/"), do: dir, else: dir <> "/"
    if not File.exists?("#{dir}serum.json") do
      IO.puts "Error: `#{dir}serum.json` not found."
      IO.puts "Make sure you point at a valid Serum project directory."
    else
      IO.puts "Rebuilding Website..."
      {:ok, pid} = Agent.start_link fn -> %{} end, name: Global

      IO.puts "Reading project infodata `#{dir}serum.json`..."
      proj = "#{dir}serum.json"
             |> File.read!
             |> Poison.decode!(keys: :atoms)
             |> Map.to_list
      Agent.update Global, &(Map.put &1, :proj, proj)

      IO.puts "Loading templates..."
      ["base", "list", "page", "post", "nav"]
      |> Enum.each(fn x ->
        tree = EEx.compile_file("#{dir}templates/#{x}.html.eex")
        Agent.update Global, &(Map.put &1, "template_#{x}", tree)
      end)

      File.mkdir_p! "#{dir}site/"
      IO.puts "Created directory `#{dir}site/`."
      pageinfo = "#{dir}pages/pages.json"
                 |> File.read!
                 |> Poison.decode!(as: [%Serum.Pageinfo{}])
      {time, _} = :timer.tc(fn ->
        compile_nav pageinfo
        t1 = Task.async fn -> build_pages dir, pageinfo end
        t2 = Task.async fn -> build_posts dir end
        Task.await t1
        Task.await t2
      end)
      IO.puts "Build process took #{time}us."
      copy_assets dir

      IO.puts ""
      IO.puts "Your website is now ready to be served!"
      IO.puts "Copy(move) the contents of `#{dir}site/` directory"
      IO.puts "into your public webpages directory."
    end
  end

  defp copy_assets(dir) do
    IO.puts "Cleaning assets and media directories..."
    File.rm_rf! "#{dir}site/assets/"
    File.rm_rf! "#{dir}site/media/"
    IO.puts "Copying assets and media..."
    case File.cp_r("#{dir}assets/", "#{dir}site/assets/") do
      {:error, :enoent, _} -> IO.puts "Assets directory not found. Skipping..."
      {:ok, _} -> nil
    end
    case File.cp_r("#{dir}media/", "#{dir}site/media/") do
      {:error, :enoent, _} -> IO.puts "Media directory not found. Skipping..."
      {:ok, _} -> nil
    end
  end
end
