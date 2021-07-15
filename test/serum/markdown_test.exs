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

  - <a href="%page:docs/index">Documentation</a>
  - <a href="%post:2019-01-01-test-post">My Post</a>

  <img src="%media:images/sample.png" alt="Sample picture">

  ## Prism HTML tags are applied

  ```elixir
  defmodule Awesome do
  end
  ```

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

    assert [{"h1", _, ["Hello, world!"]}] = Floki.find(tree, "h1")

    [ul1, ul2, ul3] = Floki.find(tree, "ul")
    [img1, img2] = Floki.find(tree, "img")

    assert ul1 === ul2
    assert img1 === img2

    ul3
    |> Floki.find("li")
    |> Enum.each(fn {"li", _, [child]} -> assert is_binary(child) end)
  end
end
