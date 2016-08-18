defmodule Serum do
  import Serum.Payload
  import Serum.Build

  def init(dir) do
    dir = if String.ends_with?(dir, "/"), do: dir, else: dir<>"/"
    if File.exists? dir do
      IO.puts "Warning: The directory `#{dir}` already exists and might not be empty."
    end

    ["posts", "pages", "media", "templates", "assets/css", "assets/js", "assets/images"]
    |> Enum.each(fn x ->
      File.mkdir_p! "#{dir}#{x}"
      IO.puts "Created directory `#{dir}#{x}`."
    end)

    projinfo =
      %{site_name: "New Website",
        site_description: "Welcome to my website!",
        author: "Somebody",
        author_email: "somebody@example.com",
        base_url: "/"}
      |> Poison.encode!(pretty: true, indent: 2)
    File.open! "#{dir}serum.json", [:write, :utf8], fn f -> IO.write f, projinfo end
    IO.puts "Generated `#{dir}serum.json`."
    File.open! "#{dir}pages/index.md", [:write, :utf8], fn f -> IO.write f, "*Hello, world!*\n" end
    File.open! "#{dir}pages/pages.json", [:write, :utf8], fn f ->
      tmp = Poison.encode! [
        %Serum.Pageinfo{name: "index", type: "md", title: "Welcome!", menu: true, menu_text: "Home", menu_icon: ""}
      ], pretty: true, indent: 2
      IO.write f, tmp
    end
    IO.puts "Generated `#{dir}pages/pages.json`."

    %{base: template_base,
      nav:  template_nav,
      list: template_list,
      page: template_page,
      post: template_post}
    |> Enum.each(fn {n, t} -> File.open! "#{dir}templates/#{n}.html.eex", [:write, :utf8], &(IO.write &1, t) end)
    IO.puts "Generated essential templates into `#{dir}templates/`."

    File.open! "#{dir}.gitignore", [:write, :utf8], fn f -> IO.write f, "site\n" end
    IO.puts "Generated `#{dir}.gitignore`."

    IO.puts "\nSuccessfully initialized a new Serum project!"
    IO.puts "try `serum build #{dir}` to build the site."
  end

  def build(dir) do
    dir = if String.ends_with?(dir, "/"), do: dir, else: dir<>"/"
    if not File.exists?("#{dir}serum.json") do
      IO.puts "Error: `#{dir}serum.json` not found."
      IO.puts "Make sure you point at a valid Serum project directory."
    else
      IO.puts "Rebuilding Website..."
      {:ok, pid} = Agent.start_link fn -> %{} end, name: Global

      IO.puts "Reading project infodata `#{dir}serum.json`..."
      proj = File.read!("#{dir}serum.json")
             |> Poison.decode!(keys: :atoms!)
             |> Map.to_list

      IO.puts "Loading templates..."
      ["base", "list", "page", "post", "nav"]
      |> Enum.each(fn x ->
        tree = EEx.compile_file("#{dir}templates/#{x}.html.eex")
        Agent.update Global, &(Map.put &1, "template_#{x}", tree)
      end)

      File.mkdir_p! "#{dir}site/"
      IO.puts "Created directory `#{dir}site/`."
      pageinfo = File.read!("#{dir}pages/pages.json")
                 |> Poison.decode!(as: [%Serum.Pageinfo{}])
      {time, _} = :timer.tc(fn ->
        compile_nav proj, pageinfo
        t1 = Task.async fn -> build_pages dir, proj, pageinfo end
        t2 = Task.async fn -> build_posts dir, proj end
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

  def copy_assets(dir) do
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
