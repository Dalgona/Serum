defmodule Serum.TagTest do
  use ExUnit.Case, async: true
  import Serum.Tag

  test "batch creation of tags" do
    proj = %{base_url: "/test"}

    # Note that tags should be lexicographically sorted.
    tags = batch_create(["hello", "beautiful", "world"], proj)
    expected_names = ["beautiful", "hello", "world"]

    expected_urls = [
      "/test/tags/beautiful",
      "/test/tags/hello",
      "/test/tags/world"
    ]

    [tags, expected_names, expected_urls]
    |> Enum.zip()
    |> Enum.each(fn {tag, name, url} ->
      assert tag.name == name
      assert tag.list_url == url
    end)
  end
end
