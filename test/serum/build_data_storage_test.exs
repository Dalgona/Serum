defmodule BuildDataStorageTest do
  use ExUnit.Case, async: true
  import Serum.BuildDataStorage

  @procname {:via, Registry, {Serum.Registry, {:build_data, "bds_test"}}}

  setup_all do
    {:ok, _pid} = start_link "bds_test"
    :ok
  end

  setup do
    init "bds_test"
  end

  test "init/1" do
    assert %{} == Agent.get @procname, &(&1)
  end

  describe "put/3" do
    test "put new item" do
      put "bds_test", "hello", :world
      assert %{"hello" => :world} == Agent.get @procname, &(&1)
    end

    test "update existing item" do
      put "bds_test", "hello", :world
      put "bds_test", "hello", :elixir
      assert %{"hello" => :elixir} == Agent.get @procname, &(&1)
    end
  end

  describe "put/4" do
    test "put new item" do
      put "bds_test", "test", "hello", :world
      assert %{"test__hello" => :world} == Agent.get @procname, &(&1)
    end

    test "update existing item" do
      put "bds_test", "test", "hello", :world
      put "bds_test", "test", "hello", :elixir
      assert %{"test__hello" => :elixir} == Agent.get @procname, &(&1)
    end
  end

  describe "get/2" do
    test "get existing item" do
      put "bds_test", "hello", {:world, 42}
      assert {:world, 42} == get("bds_test", "hello")
    end

    test "get nonexistent item" do
      assert nil == get("bds_test", "asdf")
    end
  end

  describe "get/3" do
    test "get existing item" do
      put "bds_test", "test", "hello", {:world, 42}
      assert {:world, 42} == get("bds_test", "test", "hello")
    end

    test "get nonexistent item" do
      assert nil == get("bds_test", "abc", "xyz")
    end
  end

  describe "delete/2" do
    test "delete existing item" do
      put "bds_test", "hello", :world
      put "bds_test", "lorem", :ipsum
      delete "bds_test", "hello"
      assert %{"lorem" => :ipsum} == Agent.get @procname, &(&1)
    end

    test "delete nonexistent item" do
      put "bds_test", "lorem", :ipsum
      delete "bds_test", "hello"
      assert %{"lorem" => :ipsum} == Agent.get @procname, &(&1)
    end
  end

  describe "delete/3" do
    test "delete existing item" do
      put "bds_test", "test", "hello", :world
      put "bds_test", "test", "lorem", :ipsum
      delete "bds_test", "test", "hello"
      assert %{"test__lorem" => :ipsum} == Agent.get @procname, &(&1)
    end

    test "delete nonexistent item" do
      put "bds_test", "lorem", :ipsum
      delete "bds_test", "test", "hello"
      assert %{"lorem" => :ipsum} == Agent.get @procname, &(&1)
    end
  end
end
