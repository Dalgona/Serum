defmodule Serum.Plugins.TableOfContentsTest do
  use ExUnit.Case, async: true
  alias Serum.Plugins.TableOfContents

  test "without attribute" do
    html = Floki.parse(get_data())
    {:ok, html2} = TableOfContents.rendering_fragment(html, %{type: :page})
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
    {:ok, html2} = TableOfContents.rendering_fragment(html, %{type: :post})
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
    assert {:ok, ^html} = TableOfContents.rendering_fragment(html, %{type: :page})
  end

  test "garbage in, something reasonable out" do
    html1 = Floki.parse(get_data())
    html2 = Floki.parse(get_data("a", "b"))
    result1 = TableOfContents.rendering_fragment(html1, %{type: :page})
    result2 = TableOfContents.rendering_fragment(html2, %{type: :page})

    assert result1 === result2
  end

  defp get_data, do: data("")
  defp get_data(start, end_), do: data(~s( start="#{start}" end="#{end_}"))

  defp data(attr),
    do: """
    <serum-toc#{attr}></serum-toc>
    <h1>The</h1>
    <h2>Quick</h2>
    <h3>Brown</h3>
    <h4>Fox</h4>
    <h5>Jumps</h5>
    <h6>Over</h6>
    <h2>The</h2>
    <h3>Lazy</h3>
    <h4>Dog</h4>
    <h2>Lorem</h2>
    <h3>Ipsum</h3>
    """
end
