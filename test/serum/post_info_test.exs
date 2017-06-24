defmodule PostInfoTest do
  use ExUnit.Case
  import Serum.PostInfo

  # Serum.PostInfo <<struct>>
  #   file: path of the soruce file on disk
  #   title: title of the blog post
  #   date: formatted string representation of post date
  #   raw_date: {{y, m, d}, {h, min, s}}
  #   tags: list of tags
  #   url: absolute path of the post (on the web)
  #   preview_text: you already know
  #   html: full contents in html

  describe "new/4" do
    # Serum.PostInfo.new(filename, header, html, state)

    test "typical usage" do
      info = new filename(), header(), html(), state()
      assert info.file == filename()
      assert info.title == header().title
      assert info.date == "2017-06-24"
      assert info.raw_date == {{2017, 6, 24}, {14, 55, 0}}
      assert info.tags == [
        %Serum.Tag{name: "serum", list_url: "/test_base/tags/serum/index.html"},
        %Serum.Tag{name: "test", list_url: "/test_base/tags/test/index.html"}
      ]
      assert info.url == "/test_base/posts/2017-06-24-test-post.html"
      assert info.preview_text ==
        "Lorem ipsum dolor sit amet "
        <> "The quick brown fox jumps over the lazy dog. "
        <> "The quick brown fox jumps over the lazy dog."
      assert info.html == html()
    end

    test "empty html" do
      info = new filename(), header(), html(:empty), state()
      assert info.file == filename()
      assert info.title == header().title
      assert info.date == "2017-06-24"
      assert info.raw_date == {{2017, 6, 24}, {14, 55, 0}}
      assert info.tags == [
        %Serum.Tag{name: "serum", list_url: "/test_base/tags/serum/index.html"},
        %Serum.Tag{name: "test", list_url: "/test_base/tags/test/index.html"}
      ]
      assert info.url == "/test_base/posts/2017-06-24-test-post.html"
      assert info.preview_text == ""
      assert info.html == ""
    end

    test "untagged" do
      info = new filename(), header(:no_tag), html(), state()
      assert info.file == filename()
      assert info.title == header().title
      assert info.date == "2017-06-24"
      assert info.raw_date == {{2017, 6, 24}, {14, 55, 0}}
      assert info.tags == []
      assert info.url == "/test_base/posts/2017-06-24-test-post.html"
      assert info.preview_text ==
        "Lorem ipsum dolor sit amet "
        <> "The quick brown fox jumps over the lazy dog. "
        <> "The quick brown fox jumps over the lazy dog."
      assert info.html == html()
    end

    test "truely useless post" do
      info = new filename(), header(:no_tag), html(:empty), state()
      assert info.file == filename()
      assert info.title == header().title
      assert info.date == "2017-06-24"
      assert info.raw_date == {{2017, 6, 24}, {14, 55, 0}}
      assert info.tags == []
      assert info.url == "/test_base/posts/2017-06-24-test-post.html"
      assert info.preview_text == ""
      assert info.html == ""
    end

    test "truncated preview" do
      info = new filename(), header(), html(), state(:short_preview)
      assert info.file == filename()
      assert info.title == header().title
      assert info.date == "2017-06-24"
      assert info.raw_date == {{2017, 6, 24}, {14, 55, 0}}
      assert info.tags == [
        %Serum.Tag{name: "serum", list_url: "/test_base/tags/serum/index.html"},
        %Serum.Tag{name: "test", list_url: "/test_base/tags/test/index.html"}
      ]
      assert info.url == "/test_base/posts/2017-06-24-test-post.html"
      assert info.preview_text == "Lorem ipsu"
      assert info.html == html()
    end
  end

  #
  # DATA
  #

  # We assume that all input data are distilled on the way to this function.

  defp filename, do: "/project/test_site/posts/2017-06-24-test-post.md"

  defp header, do: %{
    title: "Test Post",
    date: Timex.to_datetime({{2017, 6, 24}, {14, 55, 0}}, :local),
    tags: ["test", "serum"]
  }

  defp header(:no_tag), do: %{
    title: "Test Post",
    date: Timex.to_datetime({{2017, 6, 24}, {14, 55, 0}}, :local)
  }

  defp html(), do: """
  <h2>Hello, world!</h2>
  <p>Lorem ipsum dolor sit amet</p>
  <p>The quick <i>brown fox</i> jumps over the lazy dog.</p>
  <p>The quick brown fox jumps <a>over the lazy dog</a>.</p>
  """

  defp html(:empty), do: ""

  defp state, do: %{
    project_info: %{
      base_url: "/test_base/",
      date_format: "{YYYY}-{0M}-{0D}",
      preview_length: 200
    },
    src: "/project/test_site/"
  }

  defp state(:short_preview), do: %{
    project_info: %{
      base_url: "/test_base/",
      date_format: "{YYYY}-{0M}-{0D}",
      preview_length: 10
    },
    src: "/project/test_site/"
  }
end
