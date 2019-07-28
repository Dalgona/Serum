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

    test "fails when an invalid integer is given" do
      data = """
      ---
      my_int: 42abcd123
      ---
      """

      assert {:invalid, _} = parse_header(data, @options)
    end

    test "parses valid datetime values" do
      data = """
      ---
      my_date1: 2019-01-01
      my_date2: 2019-01-01 12:34:56
      ---
      """

      {:ok, {map, %{}, _}} = parse_header(data, @options)

      assert {{2019, 1, 1}, {0, 0, 0}} == Timex.to_erl(map.my_date1)
      assert {{2019, 1, 1}, {12, 34, 56}} == Timex.to_erl(map.my_date2)
    end

    test "parses valid lists of values" do
      data = """
      ---
      my_strs: lorem, ipsum,dolor , sit
      my_ints: 10, 20,30 ,40 , 50
      my_dates: 2019-01-01, 2019-01-01 12:34:56
      ---
      """

      strs = ["lorem", "ipsum", "dolor", "sit"]
      ints = [10, 20, 30, 40, 50]

      assert {:ok, {%{my_strs: ^strs, my_ints: ^ints, my_dates: dates}, %{}, _}} =
               parse_header(data, @options)

      assert [{{2019, 1, 1}, {0, 0, 0}}, {{2019, 1, 1}, {12, 34, 56}}] ==
               Enum.map(dates, &Timex.to_erl/1)
    end

    test "fails when an invalid list of integers is given" do
      data = """
      ---
      my_ints: 10, 20, a, 40b
      ---
      """

      assert {:invalid, _} = parse_header(data, @options)
    end

    test "fails when an invalid list of dates is given" do
      data = """
      ---
      my_dates: 2019-01-01, 20190101
      ---
      """

      assert {:invalid, _} = parse_header(data, @options)
    end

    test "rejects list of lists" do
      data = """
      ---
      x: how, does, one, know, how, many, sub, lists, exist, here
      ---
      """

      assert {:invalid, _} = parse_header(data, x: {:list, {:list, :string}})
    end

    test "rejects a value with an invalid type" do
      data = """
      ---
      magic: <!#>$#*&(*)
      ---
      """

      assert {:invalid, _} = parse_header(data, magic: :spell)
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
