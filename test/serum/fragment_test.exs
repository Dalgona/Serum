defmodule Serum.FragmentTest do
  use Serum.Case, async: true
  alias Serum.Fragment

  @html """
  <h1>Test HTML Document</h1>
    <p>The quick brown fox jumps over the lazy dog.</p>
    <img src="/media/image1.png">
  <h2 id="section-two">Lorem Ipsum</h2>
    <p>The quick brown fox jumps over the lazy dog.</p>
    <img src="/media/image2.png">
  <h3>Example</h3>
    <p>The quick brown fox jumps over the lazy dog.</p>
  <h2>테스트 1</h2>
    <img src="/media/image3.png">
    <p>The quick brown fox jumps over the lazy dog.</p>
  <h3>Example</h3>
    <p>The quick brown fox jumps over the lazy dog.</p>
  <h2>Test 2</h2>
    <p>The quick brown fox jumps over the lazy dog.</p>
  <h3>Example</h3>
    <p>The quick brown fox jumps over the lazy dog.</p>
  <h4 id="foo">FooBarBaz</h4>
  """

  setup_all do
    {:ok, frag} = Fragment.new("src", "dest", %{type: :page}, @html)

    {:ok, fragment: frag}
  end

  describe "new/4" do
    test "collects image information", %{fragment: frag} do
      expected_imgs = [
        "/media/image1.png",
        "/media/image2.png",
        "/media/image3.png"
      ]

      frag.metadata.images
      |> Enum.zip(expected_imgs)
      |> Enum.each(fn {img, expected} -> assert img === expected end)
    end

    test "automatically sets an id for each heading tag", %{fragment: frag} do
      expected_ids = [
        "test-html-document",
        "section-two",
        "example",
        "테스트-1",
        "example-2",
        "test-2",
        "example-3",
        "foo"
      ]

      frag.data
      |> Floki.parse_document!()
      |> Floki.traverse_and_update([], &get_ids/2)
      |> elem(1)
      |> Enum.reverse()
      |> Enum.zip(expected_ids)
      |> Enum.each(fn {id, expected} -> assert id === expected end)
    end
  end

  defp get_ids({<<?h, ch::8>>, attrs, _} = tree, ids) when ch in ?1..?6 do
    case Enum.find(attrs, fn {k, _} -> k === "id" end) do
      {"id", id} -> {tree, [id | ids]}
      _ -> {tree, ["** ID IS NOT SET **" | ids]}
    end
  end

  defp get_ids(x, ids), do: {x, ids}
end
