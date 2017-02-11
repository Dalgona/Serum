defmodule PostInfoTest do
  use ExUnit.Case, async: true
  alias Serum.PostInfo

  test "new/5" do
    info = PostInfo.new(
      "2017-02-04-1948-test-post",
      {"Test Post", [], []},
      {{2017, 2, 4}, {19, 48, 0}},
      "Hello, world!",
      %{project_info:
       %{base_url: "/test_base/", date_format: "{WDfull}, {D} {Mshort} {YYYY}"}}
    )
    expected = %PostInfo{
      file: "2017-02-04-1948-test-post",
      title: "Test Post",
      tags: [],
      preview_text: "Hello, world!",
      raw_date: {{2017, 2, 4}, {19, 48, 0}},
      date: "Saturday, 4 Feb 2017",
      url: "/test_base/posts/2017-02-04-1948-test-post.html"
    }
    assert expected == info
  end
end
