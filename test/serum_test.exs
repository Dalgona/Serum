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
    put_data("key", 123)
    assert %{"key" => 123} == build_data()
  end

  test "get_data/1" do
    init_data()
    put_data("a", 1)
    assert 1 == get_data("a")
  end

  test "put_data/3" do
    init_data()
    put_data("x", "y", 123)
    assert %{"x__y" => 123} == build_data()
  end

  test "get_data/2" do
    init_data()
    put_data("x", "y", 123)
    assert 123 == get_data("x", "y")
  end

  test "del_data/1" do
    init_data()
    put_data("x", 123)
    assert %{"x" => 123} == build_data()
    del_data("x")
    assert %{} == build_data()
  end

  test "del_data/2" do
    init_data()
    put_data("x", "y", 123)
    assert %{"x__y" => 123} == build_data()
    del_data("x", "y")
    assert %{} == build_data()
  end

  defp build_data do
    Agent.get Serum.BuildData, & &1
  end
end
