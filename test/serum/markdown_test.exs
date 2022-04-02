defmodule Serum.MarkdownTest do
  use ExUnit.Case, async: true
  alias Serum.Markdown

  @markdown """
  # Hello, world!

  The quick brown fox jumps over the lazy dog.

  ## Special Syntax Test

  - [Documentation](%page:docs/index)
  - [My Post](%post:2019-01-01-test-post)

  ![Sample picture](%media:images/sample.png)

  ## Special Syntax in HTML

  <ul>
    <li><a href="%page:docs/index">Documentation</a></li>
    <li><a href="%post:2019-01-01-test-post">My Post</a></li>
  </ul>

  Mixing markdown and HTML does not work in recent version of Earmark!
  The following code will produce an undesired markup!

  - <a href="%page:docs/index">Documentation</a>
  - <a href="%post:2019-01-01-test-post">My Post</a>

  <img src="%media:images/sample.png" alt="Sample picture">

  ## These won't be processed

  - %page:docs/index
  - %post:2019-01-01-test-post
  - %media:images/sample.png
  """

  test "to_html" do
    tree =
      @markdown
      |> Markdown.to_html(%{base_url: "/test_site/"})
      |> Floki.parse_document!()

    assert [{"h1", _, [h1_text]}] = Floki.find(tree, "h1")
    assert String.trim(h1_text) === "Hello, world!"

    [ul1, ul2, ul3, _ul4] = Floki.find(tree, "ul")
    [img1, img2] = Floki.find(tree, "img")

    assert ul1 === ul2
    assert img1 === img2

    ul3
    |> Floki.find("li")
    |> Enum.each(fn {"li", _, [child]} -> assert is_binary(child) end)
  end
end
