defmodule Serum.Plugins.SitemapGenerator do
  @moduledoc """
  A Serum plugin that create a sitemap so that the search engine can index posts.

  ## Using the Plugin

      # serum.exs:
      %{
        server_root: "https://example.io",
        plugins: [
          {Serum.Plugins.SitemapGenerator, only: :prod}
        ]
      }
  """

  @behaviour Serum.Plugin

  require EEx
  alias Serum.GlobalBindings

  def name, do: "Create sitemap for search engine"
  def version, do: "1.0.0"
  def elixir, do: ">= 1.6.0"
  def serum, do: "0.12.0"

  def description do
    "Create a sitemap so that the search engine can index posts."
  end

  def implements,
    do: [
      :build_succeeded
    ]

  def build_succeeded(_src, dest) do
    with :ok <- write_sitemap(dest),
         :ok <- write_robots(dest) do
      :ok
    else
      {:error, _} = error -> error
    end
  end

  res_dir =
    :serum
    |> :code.priv_dir()
    |> IO.iodata_to_binary()
    |> Path.join("build_resources")

  sitemap_path = Path.join(res_dir, "sitemap.xml.eex")
  robots_path = Path.join(res_dir, "robots.txt.eex")

  EEx.function_from_file(:defp, :sitemap_xml, sitemap_path, [
    :all_posts,
    :transformer,
    :server_root
  ])

  EEx.function_from_file(:defp, :robots_txt, robots_path, [:sitemap_path])

  defp to_w3c_format(erl_datetime) do
    # reference to https://www.w3.org/TR/NOTE-datetime
    Timex.format!(erl_datetime, "%Y-%m-%d", :strftime)
  end

  defp get_server_root do
    :site
    |> GlobalBindings.get()
    |> Map.fetch!(:server_root)
  end

  defp write_sitemap(dest) do
    all_posts = GlobalBindings.get(:all_posts)
    sitemap = sitemap_xml(all_posts, &to_w3c_format/1, get_server_root())

    try_save(sitemap, Path.join(dest, "sitemap.xml"))
  end

  defp write_robots(dest) do
    sitemap_path = Path.join(get_server_root(), "sitemap.xml")
    robots = robots_txt(sitemap_path)

    try_save(robots, Path.join(dest, "robots.txt"))
  end

  defp try_save(data, dest) do
    with {:ok, pid} <- File.open(dest, [:write, :utf8]),
         :ok <- IO.write(pid, data),
         :ok <- File.close(pid) do
      IO.puts("\x1b[92m   GEN \x1b[0m#{dest}")
      :ok
    else
      {:error, reason} -> {:error, {reason, dest, 0}}
    end
  end
end
