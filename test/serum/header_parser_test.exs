defmodule Serum.HeaderParserTest do
  use ExUnit.Case, async: true
  import Serum.HeaderParser

  @options [
    my_str: :string,
    my_int: :integer,
    my_date1: :datetime,
    my_date2: :datetime,
    my_strs: {:list, :string},
    my_ints: {:list, :integer},
    my_dates: {:list, :datetime}
  ]

  @required [:my_str, :my_int]

  describe "parse_header/3" do
    test "parses header with required keys only" do
      data = """
      ---
      my_str: Hello, world!
      my_int: 42
      ---
      """

      expected = %{
        my_str: "Hello, world!",
        my_int: 42
      }

      assert {:ok, {^expected, %{}, _}} = parse_header(data, @options, @required)
    end

    test "fails when single required key is missing" do
      data = """
      ---
      my_str: Hello
      ---
      """

      assert {:invalid, msg} = parse_header(data, @options, @required)
      assert String.ends_with?(msg, "it's missing")
    end

    test "fails when multiple required keys are missing" do
      data = """
      ---
      my_ints: 1, 2, 3
      ---
      """

      assert {:invalid, msg} = parse_header(data, @options, @required)
      assert String.ends_with?(msg, "they are missing")
    end

    test "parses extra metadata" do
      data = """
      ---
      my_str: Hello, world!
      extra1: Lorem ipsum
      ---
      """

      expected = %{my_str: "Hello, world!"}
      expected_extra = %{"extra1" => "Lorem ipsum"}

      assert {:ok, {^expected, ^expected_extra, _}} = parse_header(data, @options)
    end

    test "ignores preceding data" do
      data = """
      notice me
      OwO
      ---
      my_str: Hello, world!
      my_int: 42
      ---
      """

      expected = %{
        my_str: "Hello, world!",
        my_int: 42
      }

      assert {:ok, {^expected, %{}, _}} = parse_header(data, @options)
    end

    test "fails when no header is found" do
      data = """
      NOTICE!
      ME!
      ÒωÓ
      """

      assert {:invalid, _} = parse_header(data, @options)
    end
  end
end
