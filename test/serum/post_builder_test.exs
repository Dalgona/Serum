defmodule PostBuilderTest do
  use ExUnit.Case, async: true
  alias Serum.Build.PostBuilder
  alias Serum.ProjectInfo
  alias Serum.ProjectInfoStorage
  alias Serum.SiteBuilder
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

  setup_all do
    {:ok, pid} = SiteBuilder.start_link "", ""
    info = ProjectInfo.new %{"base_url" => "/test_base/"}
    ProjectInfoStorage.load pid, info
    on_exit fn -> SiteBuilder.stop pid end
    {:ok, [builder: pid]}
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

    # Yeah, this function permits this kind of date, for now.
    # Timex may raise an error.
    test "ridiculous date" do
      expected = {:ok, {{2017, 33, 66}, {18, 55, 0}}}
      result = PostBuilder.extract_date "2017-33-66-1855-hyper-date.md"
      assert expected == result
    end
  end

  describe "extract_header/1" do
    test "good post", %{builder: pid} do
      expected =
        {:ok,
         {"An Example of Well-formed Post",
          [%Tag{name: "example", list_url: "/test_base/tags/example"},
           %Tag{name: "serum", list_url: "/test_base/tags/serum"},
           %Tag{name: "test", list_url: "/test_base/tags/test"}],
          ["", "Hello, world!", "",
           "The quick brown fox jumps over the lazy dog.", ""]}}
      assert expected == get_header pid, get_post("wellformed.md")
    end

    test "empty post 1", %{builder: pid} do
      expected =
        {:ok,
         {"Empty Post",
          [%Tag{name: "serum", list_url: "/test_base/tags/serum"},
           %Tag{name: "test", list_url: "/test_base/tags/test"}],
          [""]}}
      assert expected == get_header pid, get_post("an-empty-post.md")
    end

    test "empty post 2", %{builder: pid} do
      expected =
        {:ok,
         {"This Post is Also Empty",
          [%Tag{name: "serum", list_url: "/test_base/tags/serum"},
           %Tag{name: "test", list_url: "/test_base/tags/test"}],
          ["", ""]}}
      assert expected == get_header pid, get_post("another-empty-post.md")
    end

    test "untagged post", %{builder: pid} do
      expected = {:ok, {"This Post is Not Tagged", [], ["", "Test post.", ""]}}
      assert expected == get_header pid, get_post("good-post-without-tags.md")
    end

    test "no tagline", %{builder: pid} do
      path = get_post "no-tagline.md"
      expected = {:error, :post_error, {:invalid_header, path, 0}}
      assert expected == get_header pid, path
    end

    test "no header", %{builder: pid} do
      path = get_post "no-header.md"
      expected = {:error, :post_error, {:invalid_header, path, 0}}
      assert expected == get_header pid, path
    end

    test "not even an existing file" do
      expected = {:error, :file_error, {:enoent, "asdf", 0}}
      assert expected == PostBuilder.extract_header "asdf"
    end
  end

  defp get_post(fname) do
    priv = :code.priv_dir :serum
    "#{priv}/test_posts/#{fname}"
  end

  defp get_header(pid, fname) do
    t = Task.async fn -> Process.link pid; PostBuilder.extract_header fname end
    Task.await t
  end
end
