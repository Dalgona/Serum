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
  alias Serum.V2

  def name, do: "Create sitemap for search engine"
  def version, do: "1.2.0"
  def elixir, do: ">= 1.8.0"
  def serum, do: unquote(serum_req)

  def description do
    "Create a sitemap so that the search engine can index posts."
  end

  def implements, do: [build_succeeded: 3]

  def build_succeeded(_src, dest, args) do
    {pages, posts} = get_items(args[:for])

    dest
    |> create_file(pages, posts)
    |> V2.File.write()
  end

  @spec get_items(term()) :: {[Page.t()], [Post.t()]}
  defp get_items(arg)
  defp get_items(nil), do: get_items([:posts])
  defp get_items(arg) when not is_list(arg), do: get_items([arg])

  defp get_items(arg) do
    pages = if :pages in arg, do: GlobalBindings.get(:all_pages), else: []
    posts = if :posts in arg, do: GlobalBindings.get(:all_posts), else: []

    {pages, posts}
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

  @spec create_file(binary(), [Page.t()], [Post.t()]) :: V2.File.t()
  defp create_file(dest, pages, posts) do
    %V2.File{
      dest: Path.join(dest, "sitemap.xml"),
      out_data: sitemap_xml(pages, posts, &to_w3c_format/1, get_server_root())
    }
  end

  @spec to_w3c_format(DateTime.t()) :: binary()
  defp to_w3c_format(datetime) do
    # reference to https://www.w3.org/TR/NOTE-datetime
    Timex.format!(datetime, "%Y-%m-%d", :strftime)
  end

  defp get_server_root do
    :site
    |> GlobalBindings.get()
    |> Map.fetch!(:server_root)
  end
end
