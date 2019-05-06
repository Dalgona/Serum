defmodule Serum.HtmlTreeHelperTest do
  use ExUnit.Case, async: true
  alias Serum.HtmlTreeHelper, as: Html

  document = """
  <div>
    <h1>This is a <span>Test Document</span></h1>
    <span>Hello, world!</span>
    <p>
      The quick <span>brown fox</span> jumps over the <span>lazy dog</span>
    </p>
    Lorem ipsum <span>dolor</span> sit amet
  </div>
  """

  @html_tree Floki.parse(document)

  test "if traverse/2 produces expected output" do
    expected_texts = [
      "TEST DOCUMENT",
      "HELLO, WORLD!",
      "BROWN FOX",
      "LAZY DOG",
      "DOLOR"
    ]

    @html_tree
    |> Html.traverse(&upcase_spans/1)
    |> Floki.find("span")
    |> Enum.zip(expected_texts)
    |> Enum.each(fn {span, expected} ->
      assert Floki.text(span) === expected
    end)
  end

  test "if traverse/3 produces expected output" do
    tree = @html_tree

    assert {tree, 5} === Html.traverse(tree, 0, &count_spans/2)
  end

  @spec upcase_spans(Html.tree()) :: Html.tree()
  defp upcase_spans(tree)

  defp upcase_spans({"span", attrs, [text]}) when is_binary(text) do
    {"span", attrs, [String.upcase(text)]}
  end

  defp upcase_spans(tree), do: tree

  @spec count_spans(Html.tree(), integer()) :: {Html.tree(), integer()}
  defp count_spans(tree, acc)
  defp count_spans({"span", _, _} = tree, acc), do: {tree, acc + 1}
  defp count_spans(tree, acc), do: {tree, acc}
end
