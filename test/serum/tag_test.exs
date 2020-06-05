defmodule Serum.TagTest do
  use ExUnit.Case, async: true
  import Serum.Tag
  alias Serum.Project

  test "batch creation of tags" do
    proj = Project.new(%{base_url: "/test", tags_url: "blog/tags"})
    tags = batch_create(["hello", "beautiful", "world"], proj)

    # Note that tags should be sorted in lexicographic order.
    expected_names = ["beautiful", "hello", "world"]

    expected_urls = [
      "/test/blog/tags/beautiful",
      "/test/blog/tags/hello",
      "/test/blog/tags/world"
    ]

    [tags, expected_names, expected_urls]
    |> Enum.zip()
    |> Enum.each(fn {tag, name, url} ->
      assert tag.name == name
      assert tag.list_url == url
    end)
  end
end
