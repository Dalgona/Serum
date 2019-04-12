defmodule Serum.Plugins.TableOfContentsTest do
  use ExUnit.Case
  alias Serum.Fragment
  alias Serum.Plugins.TableOfContents

  test "without attribute" do
    frag = %Fragment{
      metadata: %{type: :page},
      data: get_data()
    }

    {:ok, frag2} = TableOfContents.rendered_fragment(frag)
    items = Floki.find(frag2.data, "ul.serum-toc li span.number")

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
    frag = %Fragment{
      metadata: %{type: :post},
      data: get_data(2, 4)
    }

    {:ok, frag2} = TableOfContents.rendered_fragment(frag)
    items = Floki.find(frag2.data, "ul.serum-toc li span.number")

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
    data = "Notice me (OwO)"

    frag = %Fragment{
      metadata: %{type: :page},
      data: data
    }

    assert {:ok, %{data: ^data}} = TableOfContents.rendered_fragment(frag)
  end

  test "garbage in, something reasonable out" do
    frag1 = %Fragment{
      metadata: %{type: :page},
      data: get_data()
    }

    frag2 = %Fragment{
      metadata: %{type: :page},
      data: get_data("a", "b")
    }

    result1 = TableOfContents.rendered_fragment(frag1)
    result2 = TableOfContents.rendered_fragment(frag2)

    assert result1 == result2
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
