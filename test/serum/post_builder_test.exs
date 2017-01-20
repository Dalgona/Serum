defmodule Serum.PostBuilderTest do
  use ExUnit.Case, async: true
  import Serum.Build.PostBuilder

  setup_all do
    Serum.put_data "proj", "base_url", "/test/"
  end

  describe "extract_header/1" do
    test "good post" do
      expected =
        {:ok,
         {"An Example of Well-formed Post",
          [%Serum.Tag{name: "example", list_url: "/test/tags/example"},
           %Serum.Tag{name: "serum", list_url: "/test/tags/serum"},
           %Serum.Tag{name: "test", list_url: "/test/tags/test"}],
         ["", "Hello, world!",
          "", "The quick brown fox jumps over the lazy dog.", ""]}}
      result =
        "2017-01-20-0940-well-formed-post.md"
        |> priv_post()
        |> extract_header()
      assert expected == result
    end

    test "empty post type 1" do
      expected =
        {:ok,
         {"Empty Post",
          [%Serum.Tag{name: "serum", list_url: "/test/tags/serum"},
           %Serum.Tag{name: "test", list_url: "/test/tags/test"}],
         [""]}}
      result =
        "an-empty-post.md"
        |> priv_post()
        |> extract_header()
      assert expected == result
    end

    test "empty post type 2" do
      expected =
        {:ok,
         {"Empty Post",
          [%Serum.Tag{name: "serum", list_url: "/test/tags/serum"},
           %Serum.Tag{name: "test", list_url: "/test/tags/test"}],
         [""]}}
      result =
        "an-empty-post.md"
        |> priv_post()
        |> extract_header()
      assert expected == result
    end

    test "untagged post" do
      expected =
        {:ok,
         {"This Post is Not Tagged",
          [],
         ["", "Test post.", ""]}}
      result =
        "good-post-without-tags.md"
        |> priv_post()
        |> extract_header()
      assert expected == result
    end

    test "no tagline" do
      expected =
        {:error,
         :post_error,
         {:invalid_header, "no-tagline.md" |> priv_post(), 0}}
      result =
        "no-tagline.md"
        |> priv_post()
        |> extract_header()
      assert expected == result
    end

    test "no header" do
      expected =
        {:error,
         :post_error,
         {:invalid_header, "no-header.md" |> priv_post(), 0}}
      result =
        "no-header.md"
        |> priv_post()
        |> extract_header()
      assert expected == result
    end

    test "nonexistent file" do
      expected =
        {:error,
         :file_error,
         {:enoent, "nofile.md", 0}}
      result =
        "nofile.md"
        |> extract_header()
      assert expected == result
    end
  end

  describe "extract_date/1" do
    test "good" do
      expected = {:ok, {{2017, 01, 20}, {10, 20, 0}}}
      result = extract_date "2017-01-20-1020-good.md"
      assert expected == result
    end

    test "no title slug type 1" do
      expect_fail "2017-01-20-1022.md"
    end

    test "no title slug type 2" do
      expect_fail "2017-01-20-1022-.md"
    end

    test "no way!" do
      expect_fail "666.md"
    end

    test "2-digit year" do
      expect_fail "17-01-20-1028-no-way.md"
    end

    test "no time" do
      expect_fail "2017-01-20-no-way.md"
    end

    test "no hyphen type 1" do
      expect_fail "201701201029-no-way.md"
    end

    test "no hyphen type 2" do
      expect_fail "20170120-1029-no-way.md"
    end

    test "ridiculous time type 1" do
      expected = {:ok, {{2017, 1, 20}, {23, 32, 0}}}
      result = extract_date "2017-01-20-9932-hyper-hour.md"
      assert expected == result
    end

    test "ridiculous time type 2" do
      expected = {:ok, {{2017, 1, 20}, {12, 59, 0}}}
      result = extract_date "2017-01-20-1299-hyper-minute.md"
      assert expected == result
    end

    test "ridiculous time type 3" do
      expected = {:ok, {{2017, 1, 20}, {23, 59, 0}}}
      result = extract_date "2017-01-20-9999-hyper-time.md"
      assert expected == result
    end

    test "ridiculous date" do
      expected = {:ok, {{2017, 98, 76}, {23, 59, 0}}}
      result = extract_date "2017-98-76-9999-hyper-time.md"
      assert expected == result
    end
  end

  defp priv_post(file) do
    priv = :serum |> :code.priv_dir |> IO.iodata_to_binary
    priv <> "/test_posts/#{file}"
  end

  defp expect_fail(fname) do
    expected =
      {:error,
       :post_error,
       {:invalid_filename, fname, 0}}
    result = extract_date fname
    assert expected == result
  end
end
