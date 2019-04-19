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
      result -> result
    end
  end

  defp to_w3c_format(erl_datetime) do
    # reference to https://www.w3.org/TR/NOTE-datetime
    Timex.format!(erl_datetime, "%Y-%m-%d", :strftime)
  end

  defp get_server_root() do
    :site
    |> GlobalBindings.get()
    |> Map.fetch!(:server_root)
  end

  defp read_build_resource(resource) do
    :serum
    |> :code.priv_dir()
    |> IO.iodata_to_binary()
    |> Path.join("build_resources/#{resource}")
    |> File.read!()
  end

  defp write_sitemap(dest) do
    all_posts = GlobalBindings.get(:all_posts)

    read_build_resource("sitemap_template.xml")
    |> EEx.eval_string(
      assigns: [
        all_posts: all_posts,
        transformer: &to_w3c_format/1,
        server_root: get_server_root()
      ]
    )
    |> try_save(Path.join(dest, "sitemap.xml"))
  end

  defp write_robots(dest) do
    sitemap_path = Path.join(get_server_root(), "sitemap.xml")

    read_build_resource("robots_template.txt")
    |> EEx.eval_string(assigns: [sitemap_path: sitemap_path])
    |> try_save(Path.join(dest, "robots.txt"))
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
