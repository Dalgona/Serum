defmodule HeaderParserTest do
  use ExUnit.Case
  import Serum.HeaderParser

  # types
  #   :string
  #   :integer
  #   :datetime (format: "{YYYY}-{0M}-{0D} {h24}:{m}:{s}")
  #   {:list, <type>}

  describe "parse_header/4" do
    # Serum.HeaderParser.parse_header(device, fname, options, required)
    #   => header

    test "test all types" do
      {:ok, sio} = StringIO.open data(:typical), [:read, :utf8]
      {:ok, map} = parse_header sio, "test.txt", options(), []
      assert map.strval == "This is the test."
      assert map.intval == 12_345
      assert map.dateval ==
        {{2017, 6, 24}, {19, 53, 27}} |> Timex.to_datetime(:local)
      assert map.strlst == ["the", "quick", "brown", "fox"]
      assert map.intlst == [1, 2, 3, 5, 8]
      assert map.datelst == [
        {{2017, 6, 24}, {10, 00, 00}} |> Timex.to_datetime(:local),
        {{2017, 6, 24}, {14, 00, 00}} |> Timex.to_datetime(:local),
        {{2017, 6, 24}, {18, 00, 00}} |> Timex.to_datetime(:local),
      ]
      StringIO.close sio
    end

    test "has required keys" do
      {:ok, sio} = StringIO.open data(:weird_pos), [:read, :utf8]
      {:ok, _} = parse_header sio, "test.txt", options(), [:strval]
      StringIO.close sio
    end

    test "one required key are missing" do
      {:ok, sio} = StringIO.open data(:weird_pos), [:read, :utf8]
      result = parse_header sio, "test.txt", options(), [:strlst]
      assert result ==
        {:error, {"`strlst` is required, but it's missing", "test.txt", 0}}
      StringIO.close sio
    end

    test "multiple required keys are missing" do
      {:ok, sio} = StringIO.open data(:weird_pos), [:read, :utf8]
      result = parse_header sio, "test.txt", options(), [:strlst, :intlst]
      assert result ==
        {:error,
         {"`strlst`, `intlst` are required, but they are missing",
          "test.txt", 0}}
      StringIO.close sio
    end

    test "no header" do
      {:ok, sio} = StringIO.open data(:no_header), [:read, :utf8]
      result = parse_header sio, "test.txt", options(), []
      assert result ==
        {:error, {"header parse error: header not found", "test.txt", 0}}
      StringIO.close sio
    end

    test "unexpected eof" do
      {:ok, sio} = StringIO.open data(:unexpected_eof), [:read, :utf8]
      result = parse_header sio, "test.txt", options(), []
      assert result ==
        {:error,
         {"header parse error: encountered unexpected end of file",
          "test.txt", 0}}
      StringIO.close sio
    end

    test "int parse error" do
      {:ok, sio} = StringIO.open data(:bad_int), [:read, :utf8]
      result = parse_header sio, "test.txt", options(), []
      assert result ==
        {:error,
         {"header parse error: `intval`: invalid integer", "test.txt", 0}}
      StringIO.close sio
    end

    test "datetime parse error" do
      {:ok, sio} = StringIO.open data(:bad_date), [:read, :utf8]
      result = parse_header sio, "test.txt", options(), []
      {:error, {msg, "test.txt", 0}} = result
      assert String.starts_with? msg, "header parse error: `dateval`: "
      StringIO.close sio
    end

    test "int list parse error" do
      {:ok, sio} = StringIO.open data(:bad_intlst), [:read, :utf8]
      result = parse_header sio, "test.txt", options(), []
      assert result ==
        {:error,
         {"header parse error: `intlst`: invalid integer", "test.txt", 0}}
      StringIO.close sio
    end

    test "list of lists" do
      {:ok, sio} = StringIO.open data(:bad_intlst), [:read, :utf8]
      result = parse_header sio, "test.txt", [intlst: {:list, {:list, :_}}], []
      assert result ==
        {:error,
         {"header parse error: `intlst`: "
          <> "\"list of lists\" type is not supported", "test.txt", 0}}
      StringIO.close sio
    end

    test "nothing on the right side" do
      {:ok, sio} = StringIO.open data(:no_value), [:read, :utf8]
      {:ok, map} = parse_header sio, "test.txt", options(), []
      assert map.strval == ""
      StringIO.close sio
    end

    test "weird value type" do
      {:ok, sio} = StringIO.open data(:bad_intlst), [:read, :utf8]
      result = parse_header sio, "test.txt", [intlst: :heroes_of_the_storm], []
      assert result ==
        {:error,
         {"header parse error: `intlst`: invalid value type", "test.txt", 0}}
      StringIO.close sio
    end

    test "using undefined keys" do
      # Any keys not specified in `options` argument shall be discarded.
      {:ok, sio} = StringIO.open data(:typical), [:read, :utf8]
      opts = [strval: :string, intval: :integer]
      {:ok, map} = parse_header sio, "test.txt", opts, []
      assert map.strval == "This is the test."
      assert map.intval == 12_345
      assert_raise KeyError, fn -> map.dateval end
      assert_raise KeyError, fn -> map.strlst end
      assert_raise KeyError, fn -> map.intlst end
      assert_raise KeyError, fn -> map.datelst end
      StringIO.close sio
    end
  end

  describe "skip_header/1" do
    # Serum.HeaderParser.skip_header(device) => new device

    test "typical usage" do
      # Must have the remaining parts
      {:ok, sio} = StringIO.open data(:typical), [:read, :utf8]
      sio2 = skip_header sio
      assert IO.read(sio2, :all) ==
        """
        Hello, world!
        The quick brown fox jumps over the lazy dog.
        """
      StringIO.close sio2
    end

    test "no header" do
      # Should end up with EOF'd I/O device.
      {:ok, sio} = StringIO.open data(:no_header), [:read, :utf8]
      sio2 = skip_header sio
      assert IO.read(sio2, 1) == :eof
      StringIO.close sio2
    end

    test "header in the middle of the stream" do
      # The first part should be discarded.
      {:ok, sio} = StringIO.open data(:weird_pos), [:read, :utf8]
      sio2 = skip_header sio
      assert IO.read(sio2, :all) == "But it still works, I hope.\n"
      StringIO.close sio2
    end

    test "header which is not closed" do
      # Should end up with EOF'd I/O device.
      {:ok, sio} = StringIO.open data(:unexpected_eof), [:read, :utf8]
      sio2 = skip_header sio
      assert IO.read(sio2, 1) == :eof
      StringIO.close sio2
    end
  end

  #
  # DATA
  #

  defp options, do: [
    strval: :string, intval: :integer, dateval: :datetime,
    strlst: {:list, :string}, intlst: {:list, :integer},
    datelst: {:list, :datetime}
  ]

  defp data(:typical), do: """
  ---
  strval: This is the test.
  intval: 12345
  dateval: 2017-06-24 19:53:27
  strlst: the, quick,brown , fox
  intlst: 1, 2,3 , 5 ,8
  datelst: 2017-06-24 10:00:00, 2017-06-24 14:00:00, 2017-06-24 18:00:00
  ---
  Hello, world!
  The quick brown fox jumps over the lazy dog.
  """

  defp data(:no_header), do: """
  This data has no header.
  What will happen?
  """

  defp data(:weird_pos), do: """
  How silly it is!
  ---
  strval: Indeed.
  intval: 57
  ---
  But it still works, I hope.
  """

  defp data(:unexpected_eof), do: """
  ---
  strval: A stupid way to make a header.
  intval: 321
  """

  defp data(:no_value), do: """
  ---
  strval:
  ---
  Seriously, why???
  """

  defp data(:bad_int), do: """
  ---
  intval: aw, snap!
  ---
  """

  defp data(:bad_date), do: """
  ---
  dateval: AW, SNAP!
  ---
  """

  defp data(:bad_intlst), do: """
  ---
  intlst: 1, 2, spy, 4
  ---
  """
end
