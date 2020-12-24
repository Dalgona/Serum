defmodule Serum.Plugins.SitemapGenerator do
  @moduledoc """
  A Serum plugin that create a sitemap so that the search engine can index posts.

  ## Using the Plugin

      # serum.exs:
      %{
        plugins: [
          {Serum.Plugins.SitemapGenerator, only: :prod}
        ]
      }
  """

  use Serum.V2.Plugin
  require EEx
  require Serum.V2.Result, as: Result
  alias Serum.V2
  alias Serum.V2.BuildContext
  alias Serum.V2.Page
  alias Serum.V2.Post
  alias Serum.V2.Project

  @type state :: %{
          args: keyword(),
          pages: [Page.t()],
          posts: [Post.t()]
        }

  def name, do: "Create sitemap for search engine"

  def description do
    "Create a sitemap so that the search engine can index posts."
  end

  def implements do
    [
      build_succeeded: 2,
      processed_pages: 2,
      processed_posts: 2
    ]
  end

  @spec init(keyword()) :: Result.t(state())
  def init(args), do: Result.return(%{args: args, pages: [], posts: []})

  @spec processed_pages([Page.t()], state()) :: Result.t({[Page.t()], state()})
  def processed_pages(pages, state) do
    new_state =
      case state.args[:for] do
        nil -> state
        targets -> if(:pages in targets, do: %{state | pages: pages}, else: state)
      end

    Result.return({pages, new_state})
  end

  @spec processed_posts([Post.t()], state()) :: Result.t({[Post.t()], state()})
  def processed_posts(posts, state) do
    new_state =
      case state.args[:for] do
        nil -> %{state | posts: posts}
        targets -> if(:posts in targets, do: %{state | posts: posts}, else: state)
      end

    Result.return({posts, new_state})
  end

  @spec build_succeeded(BuildContext.t(), state()) :: Result.t(state())
  def build_succeeded(%BuildContext{dest_dir: dest, project: project}, state) do
    server_root = to_string(%URI{project.base_url | path: "/"})

    dest
    |> create_file(state.pages, state.posts, server_root)
    |> V2.File.write()

    Result.return(state)
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

  @spec create_file(binary(), [Page.t()], [Post.t()], binary()) :: V2.File.t()
  defp create_file(dest, pages, posts, server_root) do
    %V2.File{
      dest: Path.join(dest, "sitemap.xml"),
      out_data: sitemap_xml(pages, posts, &to_w3c_format/1, server_root)
    }
  end

  @spec to_w3c_format(DateTime.t()) :: binary()
  defp to_w3c_format(datetime) do
    # reference to https://www.w3.org/TR/NOTE-datetime
    Timex.format!(datetime, "%Y-%m-%d", :strftime)
  end
end
