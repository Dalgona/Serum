defmodule Serum.HeaderParser.ValueTransformerTest do
  use Serum.Case, async: true
  import Serum.HeaderParser.ValueTransformer
  alias Serum.V2.Error

  describe "transform_value/3" do
    test "parses an integer value" do
      assert {:ok, 42} === transform_value({"my_int", "42"}, :integer)
    end

    test "fails when an invalid integer is given" do
      assert {:error, %Error{}} = transform_value({"my_int", "xyz"}, :integer)
    end

    test "parses valid datetime values" do
      inputs = [
        {{"my_date1", "2019-01-01"}, {{2019, 1, 1}, {0, 0, 0}}},
        {{"my_date2", "2019-01-01 12:34:56"}, {{2019, 1, 1}, {12, 34, 56}}}
      ]

      Enum.each(inputs, fn {kv, expected} ->
        {:ok, dt} = transform_value(kv, :datetime)

        assert ^expected = Timex.to_erl(dt)
      end)
    end

    test "fails when an invalid datetime is given" do
      assert {:error, %Error{}} = transform_value({"my_date", "yesterday"}, :datetime)
    end

    test "parses a valid list of strings" do
      input = "the,quick, brown ,fox"
      expected = {:ok, ~w(the quick brown fox)}

      assert expected === transform_value({"test", input}, {:list, :string})
    end

    test "parses a valid list of integers" do
      input = "10,20, 30 ,40"
      expected = {:ok, [10, 20, 30, 40]}

      assert expected === transform_value({"test", input}, {:list, :integer})
    end

    test "fails when invalid integers are present in a list" do
      input = "10, 20, abc, 40"

      assert {:error, %Error{}} = transform_value({"test", input}, {:list, :integer})
    end

    test "parses a valid list of datetimes" do
      input = "2019-07-29, 2019-07-29 12:34:56"
      expected = [{{2019, 7, 29}, {0, 0, 0}}, {{2019, 7, 29}, {12, 34, 56}}]
      {:ok, result} = transform_value({"test", input}, {:list, :datetime})

      assert expected === Enum.map(result, &Timex.to_erl/1)
    end

    test "fails when invalid datetimes are present in a list" do
      input = "2019-07-29, once upon a time, 2019-07-29 12:34:56"

      assert {:error, %Error{}} = transform_value({"test", input}, {:list, :datetime})
    end

    test "rejects a list of lists" do
      input = "how, does, one, know, how, many, sub, lists, exist, here?"

      assert {:error, %Error{}} = transform_value({"test", input}, {:list, {:list, :string}})
    end

    test "rejects a value with an invalid type" do
      assert {:error, %Error{}} = transform_value({"magic", "<!#>$#*&(*)"}, :spell)
    end
  end
end
