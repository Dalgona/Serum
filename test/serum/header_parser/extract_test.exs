defmodule Serum.HeaderParser.ExtractTest do
  use ExUnit.Case, async: true
  alias Serum.Error
  alias Serum.HeaderParser.Extract

  describe "extract_header/1" do
    test "extracts well-formed header from binary" do
      data = """
      This line will be ignored.
      ---
      title: Hello, world!
      tags: foo, bar
      ---
      Lorem
      Ipsum
      """

      expected_header = [
        {{"tags", "foo, bar"}, 4},
        {{"title", "Hello, world!"}, 3}
      ]

      assert {:ok, {header, "Lorem\nIpsum\n", 6}} = Extract.extract_header(data)
      assert header === expected_header
    end

    test "returns an error when there is no header" do
      data = """
      Lorem
      Ipsum
      Dolor
      """

      assert {:error, %Error{line: 4}} = Extract.extract_header(data)
    end

    test "returns an error if header is not properly closed" do
      data = """
      ===
      title: Hello, world!
      tags: foo, bar
      """

      assert {:error, %Error{line: 4}} = Extract.extract_header(data)
    end
  end
end
