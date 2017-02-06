defmodule PostBuilderTest do
  use ExUnit.Case, async: true
  alias Serum.Build.PostBuilder
  alias Serum.Tag

  defmacro expect_fail(fname) do
    quote do
      expected =
        {:error, :post_error,
         {:invalid_filename, unquote(fname), 0}}
      result = PostBuilder.extract_date unquote(fname)
      assert expected == result
    end
  end

  describe "make_preview/2" do
    test "zero length" do
      result = PostBuilder.make_preview "<p>AaaaaAAaaaAAAaaAAAAaAAAAA</p>", 0
      assert "" == result
    end

    test "text only, not truncated" do
      html = ~s(<p>Hello, world!</p>\n<p>Bye, world!</p>)
      assert "Hello, world! Bye, world!" == PostBuilder.make_preview html, 999
    end

    test "text and images, not truncated" do
      html = ~s(<p>Hello, world!</p><img src="a.png"><p>Bye, world!</p>)
      assert "Hello, world! Bye, world!" == PostBuilder.make_preview html, 999
    end

    test "truncated" do
      html = ~s(<p>Pneumonoultramicroscopicsilicovolcanoconiosis</p>)
      assert "Pneum" == PostBuilder.make_preview html, 5
    end
  end

  describe "extract_date/1" do
    test "good" do
      expected = {:ok, {{2017, 02, 06}, {18, 46, 0}}}
      result = PostBuilder.extract_date "2017-02-06-1846-good.md"
      assert expected == result
    end

    test "no title slug type 1" do
      expect_fail "2017-02-06-1849.md"
    end

    test "no title slug type 2" do
      expect_fail "2017-02-06-1852-.md"
    end

    test "no way!" do
      expect_fail "asdf.md"
    end

    test "ridiculous time type 1" do
      expected = {:ok, {{2017, 02, 06}, {23, 32, 0}}}
      result = PostBuilder.extract_date "2017-02-06-9932-hyper-hour.md"
      assert expected == result
    end

    test "ridiculous time type 2" do
      expected = {:ok, {{2017, 02, 06}, {18, 59, 0}}}
      result = PostBuilder.extract_date "2017-02-06-1899-hyper-minute.md"
      assert expected == result
    end

    test "ridiculous time type 3" do
      expected = {:ok, {{2017, 02, 06}, {23, 59, 0}}}
      result = PostBuilder.extract_date "2017-02-06-9999-hyper-time.md"
      assert expected == result
    end

    # TODO: Yeah, this function permits this kind of date, for now.
    # Timex may raise an error.
    test "ridiculous date" do
      expected = {:ok, {{2017, 33, 66}, {18, 55, 0}}}
      result = PostBuilder.extract_date "2017-33-66-1855-hyper-date.md"
      assert expected == result
    end
  end

  describe "extract_header/2" do
    test "good post" do
      expected =
        {:ok,
         {"An Example of Well-formed Post",
          [%Tag{name: "example", list_url: "/test_base/tags/example"},
           %Tag{name: "serum", list_url: "/test_base/tags/serum"},
           %Tag{name: "test", list_url: "/test_base/tags/test"}],
          ["", "Hello, world!", "",
           "The quick brown fox jumps over the lazy dog.", ""]}}
      assert expected == get_header "wellformed.md"
    end

    test "empty post 1" do
      expected =
        {:ok,
         {"Empty Post",
          [%Tag{name: "serum", list_url: "/test_base/tags/serum"},
           %Tag{name: "test", list_url: "/test_base/tags/test"}],
          [""]}}
      assert expected == get_header "an-empty-post.md"
    end

    test "empty post 2" do
      expected =
        {:ok,
         {"This Post is Also Empty",
          [%Tag{name: "serum", list_url: "/test_base/tags/serum"},
           %Tag{name: "test", list_url: "/test_base/tags/test"}],
          ["", ""]}}
      assert expected == get_header "another-empty-post.md"
    end

    test "untagged post" do
      expected = {:ok, {"This Post is Not Tagged", [], ["", "Test post.", ""]}}
      assert expected == get_header "good-post-without-tags.md"
    end

    test "no tagline" do
      path = get_post "no-tagline.md"
      expected = {:error, :post_error, {:invalid_header, path, 0}}
      assert expected == get_header "no-tagline.md"
    end

    test "no header" do
      path = get_post "no-header.md"
      expected = {:error, :post_error, {:invalid_header, path, 0}}
      assert expected == get_header "no-header.md"
    end

    test "not even an existing file" do
      expected = {:error, :file_error, {:enoent, "asdf", 0}}
      assert expected == PostBuilder.extract_header "asdf", "/test_base/"
    end
  end

  defp get_post(fname) do
    priv = :code.priv_dir :serum
    "#{priv}/test_posts/#{fname}"
  end

  defp get_header(fname) do
    fname
    |> get_post()
    |> PostBuilder.extract_header("/test_base/")
  end
end
