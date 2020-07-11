defmodule Serum.HeaderParserTest do
  use Serum.Case, async: true
  import Serum.HeaderParser
  alias Serum.HeaderParser.ParseResult
  alias Serum.V2

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

      file = %V2.File{src: "testfile", in_data: data}

      expected = %ParseResult{
        data: %{
          my_str: "Hello, world!",
          my_int: 42
        },
        extras: %{},
        rest: "",
        next_line: 5
      }

      assert {:ok, ^expected} = parse_header(file, @options, @required)
    end

    test "fails when single required key is missing" do
      data = """
      ---
      my_str: Hello
      ---
      """

      file = %V2.File{src: "testfile", in_data: data}

      assert {:error, error} = parse_header(file, @options, @required)
      assert to_string(error) =~ "is required"
    end

    test "fails when multiple required keys are missing" do
      data = """
      ---
      my_ints: 1, 2, 3
      ---
      """

      file = %V2.File{src: "testfile", in_data: data}

      assert {:error, error} = parse_header(file, @options, @required)
      assert to_string(error) =~ "are required"
    end

    test "parses extra metadata" do
      data = """
      ---
      my_str: Hello, world!
      extra1: Lorem ipsum
      ---
      """

      file = %V2.File{src: "testfile", in_data: data}

      expected = %ParseResult{
        data: %{my_str: "Hello, world!"},
        extras: %{"extra1" => "Lorem ipsum"},
        rest: "",
        next_line: 5
      }

      assert {:ok, ^expected} = parse_header(file, @options)
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

      file = %V2.File{src: "testfile", in_data: data}

      expected = %ParseResult{
        data: %{
          my_str: "Hello, world!",
          my_int: 42
        },
        extras: %{},
        rest: "",
        next_line: 7
      }

      assert {:ok, ^expected} = parse_header(file, @options)
    end

    test "fails when no header is found" do
      data = """
      NOTICE!
      ME!
      ÒωÓ
      """

      file = %V2.File{src: "testfile", in_data: data}

      assert {:error, error} = parse_header(file, @options)
      assert to_string(error) =~ "header not found"
    end

    test "fails when parse errors occurred" do
      data = """
      ---
      my_int: asdf
      ---
      """

      file = %V2.File{src: "testfile", in_data: data}

      assert {:error, error} = parse_header(file, @options)
      assert to_string(error) =~ "invalid integer"
    end
  end
end
