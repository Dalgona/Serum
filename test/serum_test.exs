defmodule SerumTest do
  use ExUnit.Case, async: true
  import Serum

  @tag :skip
  test "start/2" do
  end

  test "init_data/0" do
    init_data()
    assert %{} == build_data()
  end

  test "put_data/2" do
    init_data()
    put_data(:a, 1)
    assert %{a: 1} == build_data()
  end

  test "get_data/1" do
    init_data()
    put_data(:a, 1)
    assert 1 == get_data(:a)
  end

  defp build_data do
    Agent.get Serum.BuildData, & &1
  end
end
