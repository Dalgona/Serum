defmodule Serum.Plugins.RssGenerator do
  @moduledoc """
  A Serum plugin that creates an RSS feed

  ## Using the Plugin

      # serum.exs:
      %{
        server_root: "https://example.io",
        plugins: [
          {Serum.Plugins.RssGenerator, only: :prod}
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

  def name, do: "Create RSS feed for humans"
  def version, do: "1.2.0"
  def elixir, do: ">= 1.8.0"
  def serum, do: unquote(serum_req)

  def description do
    "Create an RSS feed so that humans can read fresh new posts."
  end

  def implements, do: [build_succeeded: 3]

  def build_succeeded(_src, dest, args) do
    {pages, posts} = get_items(args[:for])

    dest
    |> create_file(pages, posts)
    |> Serum.File.write()
    |> case do
      {:ok, _} -> :ok
      {:error, _} = error -> error
    end
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

  rss_path =
    :serum
    |> :code.priv_dir()
    |> Path.join("build_resources")
    |> Path.join("rss.xml.eex")

  EEx.function_from_file(:defp, :rss_xml, rss_path, [
    :pages,
    :posts,
    :transformer,
    :bindings
  ])

  @spec create_file(binary(), [Page.t()], [Post.t()]) :: Serum.File.t()
  defp create_file(dest, pages, posts) do
    %Serum.File{
      dest: Path.join(dest, "rss.xml"),
      out_data: rss_xml(pages, posts, &to_rfc822_format/1, bindings())
    }
  end

  defp to_rfc822_format(_now) do
    # reference to https://www.w3.org/TR/NOTE-datetime
    # 10 Mar 21 22:43:37 UTC
    # NaiveDateTime.from_erl!()
    # Timex.now()
    # |> Timex.format!("%d %b %y %T Z", :strftime)
    # "10 Mar 21 22:43:37 UTC"
  end

  defp bindings do
    :site
    |> GlobalBindings.get()
  end
end
