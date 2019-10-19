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

  serum_ver = Version.parse!(Mix.Project.config()[:version])
  serum_req = "~> #{serum_ver.major}.#{serum_ver.minor}"

  require EEx
  alias Serum.GlobalBindings
  alias Serum.Result

  def name, do: "Create sitemap for search engine"
  def version, do: "1.1.0"
  def elixir, do: "~> 1.8"
  def serum, do: unquote(serum_req)

  def description do
    "Create a sitemap so that the search engine can index posts."
  end

  def implements, do: [build_succeeded: 3]

  def build_succeeded(_src, dest, _args) do
    with {:ok, _} <- write_sitemap(dest),
         {:ok, _} <- write_robots(dest) do
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

  @spec write_sitemap(binary()) :: Result.t(Serum.File.t())
  defp write_sitemap(dest) do
    all_posts = GlobalBindings.get(:all_posts)

    file = %Serum.File{
      dest: Path.join(dest, "sitemap.xml"),
      out_data: sitemap_xml(all_posts, &to_w3c_format/1, get_server_root())
    }

    Serum.File.write(file)
  end

  @spec write_robots(binary()) :: Result.t(Serum.File.t())
  defp write_robots(dest) do
    file = %Serum.File{
      dest: Path.join(dest, "robots.txt"),
      out_data: robots_txt(Path.join(get_server_root(), "sitemap.xml"))
    }

    Serum.File.write(file)
  end
end
