defmodule Serum.Post.PreviewGeneratorTest do
  use Serum.Case, async: true
  import Serum.Post.PreviewGenerator

  @html """
        Lorem **ipsum** dolor sit amet, consectetur _adipiscing_ elit.

        The quick brown fox jumps over the lazy dog.

        Grumpy wizards make toxic brew for the evil queen and jack.
        """
        |> Earmark.as_html!()

  describe "generate_preview/2" do
    test "returns an empty string when max chars is zero" do
      assert generate_preview(@html, 0) === ""
      assert generate_preview(@html, {:chars, 0}) === ""
    end

    test "returns an empty string when max words is zero" do
      assert generate_preview(@html, {:words, 0}) === ""
    end

    test "returns an empty string when max paragraphs is zero" do
      assert generate_preview(@html, {:paragraphs, 0}) === ""
    end

    test "properly handles an integer argument" do
      assert generate_preview(@html, 10) =~ "Lorem ipsu"
    end

    test "properly handles {:chars, length} argument" do
      assert generate_preview(@html, {:chars, 10}) =~ "Lorem ipsu"
    end

    test "properly handles {:words, length} argument" do
      assert generate_preview(@html, {:words, 4}) =~ "Lorem ipsum dolor sit"
    end

    test "properly handles {:paragraphs, length} argument" do
      preview = generate_preview(@html, {:paragraphs, 2})

      [
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
        "The quick brown fox jumps over the lazy dog."
      ]
      |> Enum.each(fn line -> assert preview =~ line end)
    end

    test "returns an empty string on invalid arguments" do
      assert generate_preview(@html, "*****") === ""
      assert generate_preview(@html, {:foobarbaz, 10}) === ""
    end
  end
end
