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
  alias Serum.Page
  alias Serum.Post

  def name, do: "Create sitemap for search engine"
  def version, do: "1.1.0"
  def elixir, do: "~> 1.8"
  def serum, do: unquote(serum_req)

  def description do
    "Create a sitemap so that the search engine can index posts."
  end

  def implements, do: [build_succeeded: 3]

  def build_succeeded(_src, dest, _args) do
    pages = GlobalBindings.get(:all_pages)
    posts = GlobalBindings.get(:all_posts)

    dest
    |> create_file(pages, posts)
    |> Serum.File.write()
    |> case do
      {:ok, _} -> :ok
      {:error, _} = error -> error
    end
  end

  sitemap_path =
    :serum
    |> :code.priv_dir()
    |> Path.join("build_resources")
    |> Path.join("sitemap.xml.eex")

  EEx.function_from_file(:defp, :sitemap_xml, sitemap_path, [
    :pages,
    :posts,
    :transformer,
    :server_root
  ])

  @spec create_file(binary(), [Page.t()], [Post.t()]) :: Serum.File.t()
  defp create_file(dest, pages, posts) do
    %Serum.File{
      dest: Path.join(dest, "sitemap.xml"),
      out_data: sitemap_xml(pages, posts, &to_w3c_format/1, get_server_root())
    }
  end

  defp to_w3c_format(erl_datetime) do
    # reference to https://www.w3.org/TR/NOTE-datetime
    Timex.format!(erl_datetime, "%Y-%m-%d", :strftime)
  end

  defp get_server_root do
    :site
    |> GlobalBindings.get()
    |> Map.fetch!(:server_root)
  end
end
