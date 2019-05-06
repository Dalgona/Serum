defmodule Serum.Plugins.TableOfContentsTest do
  use ExUnit.Case, async: true
  alias Serum.Plugins.TableOfContents, as: TOC

  test "without attribute" do
    html = Floki.parse(get_data())
    {:ok, html2} = TOC.rendering_fragment(html, %{type: :page})
    items = Floki.find(html2, "ul.serum-toc li span.number")

    assert length(items) == 11

    expected = [
      "1",
      "1.1",
      "1.1.1",
      "1.1.1.1",
      "1.1.1.1.1",
      "1.1.1.1.1.1",
      "1.2",
      "1.2.1",
      "1.2.1.1",
      "1.3",
      "1.3.1"
    ]

    items
    |> Enum.map(fn {_, _, [text | _]} -> text end)
    |> Enum.zip(expected)
    |> Enum.each(fn {real, expected} -> assert real == expected end)
  end

  test "with attribute" do
    html = Floki.parse(get_data(2, 4))
    {:ok, html2} = TOC.rendering_fragment(html, %{type: :post})
    items = Floki.find(html2, "ul.serum-toc li span.number")

    assert length(items) == 8

    expected = [
      "1",
      "1.1",
      "1.1.1",
      "2",
      "2.1",
      "2.1.1",
      "3",
      "3.1"
    ]

    items
    |> Enum.map(fn {_, _, [text | _]} -> text end)
    |> Enum.zip(expected)
    |> Enum.each(fn {real, expected} -> assert real == expected end)
  end

  test "no serum-toc tag" do
    html = Floki.parse("Notice me (OwO)")
    assert {:ok, ^html} = TOC.rendering_fragment(html, %{type: :page})
  end

  test "garbage in, something reasonable out" do
    html1 = Floki.parse(get_data())
    html2 = Floki.parse(get_data("a", "b"))
    result1 = TOC.rendering_fragment(html1, %{type: :page})
    result2 = TOC.rendering_fragment(html2, %{type: :page})

    assert result1 === result2
  end

  test "if list element has an id 'toc'" do
    html = Floki.parse(get_data())
    {:ok, html2} = TOC.rendering_fragment(html, %{type: :page})
    {"ul", attrs, _} = html2 |> Floki.find("ul.serum-toc") |> hd()

    assert Enum.any?(attrs, fn {k, v} -> k === "id" and v === "toc" end)
  end

  test "if id attribute is properly set" do
    html = Floki.parse(get_data(2, 4))
    {:ok, html2} = TOC.rendering_fragment(html, %{type: :page})
    links = Floki.find(html2, "ul.serum-toc li a")

    expected_hashes = [
      "#h2_quick",
      "#s_1.1",
      "#h4_fox",
      "#s_2",
      "#h3_lazy",
      "#s_2.1.1",
      "#h2_lorem",
      "#s_3.1"
    ]

    links
    |> Enum.zip(expected_hashes)
    |> Enum.each(fn {{"a", attrs, _}, expected} ->
      {"href", href} = Enum.find(attrs, fn {k, _} -> k === "href" end)

      assert href === expected
    end)
  end

  defp get_data, do: data("")
  defp get_data(start, end_), do: data(~s( start="#{start}" end="#{end_}"))

  defp data(attr),
    do: """
    <serum-toc#{attr}></serum-toc>
    <h1>The</h1>
    <h2 id="h2_quick"><a>Quick</a></h2>
    <h3><code>Brown</code></h3>
    <h4 id="h4_fox">Fox</h4>
    <h5>Jumps</h5>
    <h6><a>Over</a></h6>
    <h2><strong>The</strong></h2>
    <h3 id="h3_lazy">Lazy</h3>
    <h4>Dog</h4>
    <h2 id="h2_lorem"><a>Lorem</a></h2>
    <h3><em>Ipsum</em></h3>
    """
end
