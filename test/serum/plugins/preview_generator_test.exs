defmodule Serum.Plugins.PreviewGeneratorTest do
  use ExUnit.Case
  alias Serum.Page
  alias Serum.Plugins.PreviewGenerator, as: P
  alias Serum.Post

  describe "build_started/3" do
    test "succeeds if no options are explicitly given" do
      assert :ok === P.build_started("", "", [])
    end

    test "succeeds if all arguments are valid" do
      args = [
        length: [chars: 200, words: 50, paragraphs: 1],
        preview_key: "summary"
      ]

      assert :ok === P.build_started("", "", args)
    end

    test "fails if args[:length] contains invalid length specs" do
      assert {:error, _} = P.build_started("", "", length: [100])
    end

    test "fails if args[:length] is not a list" do
      assert {:error, _} = P.build_started("", "", length: 100)
    end

    test "fails if args[:preview_key] is an empty string" do
      assert {:error, _} = P.build_started("", "", preview_key: "")
    end

    test "fails if args[:preview_key] only contains whitespaces" do
      assert {:error, _} = P.build_started("", "", preview_key: "\t \n")
    end

    test "fails if args[:preview_key] is not a string" do
      assert {:error, _} = P.build_started("", "", preview_key: :foo)
    end
  end

  describe "processed_pages/2 and processed_posts/2" do
    # Operations of processed_pages/2 and processed_posts/2 are exactly the same.

    test "generates preview texts using default options" do
      {:ok, [%Page{} = page]} = P.processed_pages(dummy_pages(), [])

      assert page.extras["preview"] === "Lorem ipsum"
    end

    test "can limit preview text length by the maximum number of characters" do
      {:ok, [%Post{} = post]} = P.processed_posts(dummy_posts(), length: [chars: 5])

      assert post.extras["preview"] === "Lorem"
    end

    test "can limit preview text length by the maximum number of words" do
      {:ok, [%Page{} = page]} = P.processed_pages(dummy_pages(), length: [words: 3])

      assert page.extras["preview"] === "Lorem ipsum dolor"
    end

    test "can limit preview text length by the maximum number of paragraphs" do
      {:ok, [%Post{} = post]} = P.processed_posts(dummy_posts(), length: [paragraphs: 2])

      assert post.extras["preview"] === "Lorem ipsum dolor sit amet"
    end

    test "can pick the shortest preview text if multiple length specs are given" do
      args = [length: [paragraphs: 1, chars: 10]]
      {:ok, [%Page{} = page]} = P.processed_pages(dummy_pages(), args)

      assert page.extras["preview"] === "Lorem ipsu"
    end

    test "puts generated preview texts into a custom key" do
      {:ok, [%Post{} = post]} = P.processed_posts(dummy_posts(), preview_key: "summary")

      assert post.extras["summary"] === "Lorem ipsum"
    end

    test "does nothing if a page or post already has preview text data" do
      [%Page{} = page] = dummy_pages()
      [%Post{} = post] = dummy_posts()
      page = %Page{page | extras: %{"preview" => "Hello, world!"}}
      post = %Post{post | extras: %{"summary" => "Hello, world!"}}
      {:ok, [%Page{} = new_page]} = P.processed_pages([page], [])
      {:ok, [%Post{} = new_post]} = P.processed_pages([post], preview_key: "summary")

      assert new_page.extras["preview"] === page.extras["preview"]
      assert new_post.extras["summary"] === post.extras["summary"]
    end
  end

  @spec dummy_pages() :: [Page.t()]
  defp dummy_pages do
    [%Page{data: "<p>Lorem ipsum</p><p>dolor sit amet</p>", extras: %{}}]
  end

  @spec dummy_posts() :: [Post.t()]
  defp dummy_posts do
    [%Post{html: "<p>Lorem ipsum</p><p>dolor sit amet</p>", extras: %{}}]
  end
end
