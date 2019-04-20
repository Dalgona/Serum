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
    test "good, contains required keys only" do
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

      assert {:ok, {^expected, _}} = parse_header(data, @options, @required)
    end

    test "good, number parsed as a string" do
      data = """
      ---
      my_str: 12345
      my_int: 42
      ---
      """

      expected = %{
        my_str: "12345",
        my_int: 42
      }

      assert {:ok, {^expected, _}} = parse_header(data, @options, @required)
    end

    test "missing required key" do
      data = """
      ---
      my_str: Hello
      ---
      """

      assert {:invalid, msg} = parse_header(data, @options, @required)
      assert String.ends_with?(msg, "it's missing")
    end

    test "missing required keys" do
      data = """
      ---
      my_ints: 1, 2, 3
      ---
      """

      assert {:invalid, msg} = parse_header(data, @options, @required)
      assert String.ends_with?(msg, "they are missing")
    end

    test "invalid integer" do
      data = """
      ---
      my_int: 42abcd123
      ---
      """

      assert {:invalid, _} = parse_header(data, @options)
    end

    test "valid datetime" do
      data = """
      ---
      my_date1: 2019-01-01
      my_date2: 2019-01-01 12:34:56
      ---
      """

      {:ok, {map, _}} = parse_header(data, @options)

      assert {{2019, 1, 1}, {0, 0, 0}} == Timex.to_erl(map.my_date1)
      assert {{2019, 1, 1}, {12, 34, 56}} == Timex.to_erl(map.my_date2)
    end

    test "valid list of values" do
      data = """
      ---
      my_strs: lorem, ipsum,dolor , sit
      my_ints: 10, 20,30 ,40 , 50
      my_dates: 2019-01-01, 2019-01-01 12:34:56
      ---
      """

      strs = ["lorem", "ipsum", "dolor", "sit"]
      ints = [10, 20, 30, 40, 50]

      assert {:ok, {%{my_strs: ^strs, my_ints: ^ints, my_dates: dates}, _}} =
               parse_header(data, @options)

      assert [{{2019, 1, 1}, {0, 0, 0}}, {{2019, 1, 1}, {12, 34, 56}}] ==
               Enum.map(dates, &Timex.to_erl/1)
    end

    test "invalid list of integers" do
      data = """
      ---
      my_ints: 10, 20, a, 40b
      ---
      """

      assert {:invalid, _} = parse_header(data, @options)
    end

    test "invalid list of dates" do
      data = """
      ---
      my_dates: 2019-01-01, 20190101
      ---
      """

      assert {:invalid, _} = parse_header(data, @options)
    end

    test "list of lists is not valid" do
      data = """
      ---
      x: how, does, one, know, how, many, sub, lists, exist, here
      ---
      """

      assert {:invalid, _} = parse_header(data, x: {:list, {:list, :string}})
    end

    test "invalid value type" do
      data = """
      ---
      magic: <!#>$#*&(*)
      ---
      """

      assert {:invalid, _} = parse_header(data, magic: :spell)
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

      assert {:ok, {^expected, _}} = parse_header(data, @options)
    end

    test "no header" do
      data = """
      NOTICE!
      ME!
      ÒωÓ
      """

      assert {:invalid, _} = parse_header(data, @options)
    end
  end
end
