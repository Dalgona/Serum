defmodule PageBuilderTest do
  use ExUnit.Case, async: true
  alias Serum.Build.PageBuilder

  defmacro expect_fail(fname) do
    quote do
      expected = {:error, :page_error, {:invalid_header, unquote(fname), 0}}
      result = PageBuilder.extract_header unquote(fname)
      assert expected == result
    end
  end

  describe "extract_header/1" do
    test "good page" do
      expected = {:ok, {"Example Page", ["", "Hello, world!", ""]}}
      result = PageBuilder.extract_header get_page("good-page.md")
      assert expected == result
    end

    test "no page title" do
      expected = {:ok, {"", ["", "This page does not have a title.", ""]}}
      result = PageBuilder.extract_header get_page("no-title.md")
      assert expected == result
    end

    test "no contents" do
      expected = {:ok, {"An Empty Page", [""]}}
      result = PageBuilder.extract_header get_page("no-content.md")
      assert expected == result
    end

    test "just a pound sign" do
      expect_fail get_page("only-sharp.md")
    end

    test "no space between # and title" do
      expect_fail get_page("no-space.md")
    end

    test "no header" do
      expect_fail get_page("no-header.md")
    end

    test "not even an existing file" do
      expected = {:error, :file_error, {:enoent, "asdf.md", 0}}
      assert expected == PageBuilder.extract_header "asdf.md"
    end
  end

  defp get_page(fname) do
    "#{:code.priv_dir :serum}/test_pages/#{fname}"
  end
end
