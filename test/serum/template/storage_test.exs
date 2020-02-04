defmodule Serum.Template.StorageTest do
  use ExUnit.Case
  alias Serum.Template
  alias Serum.Template.Storage, as: TS

  @names ~w(lorem ipsum dolor)

  @data @names
        |> Enum.map(&{&1, %Template{ast: &1}})
        |> Map.new()

  setup do
    on_exit(fn ->
      Agent.update(TS, fn _ -> %{template: %{}, include: %{}} end)
    end)
  end

  describe "load/2" do
    test "loads/gets templates" do
      TS.load(@data, :template)

      Enum.each(@names, fn name ->
        assert {:ok, template} = TS.get(name, :template)
        assert template.ast === name
      end)
    end

    test "loads/gets includes" do
      TS.load(@data, :include)

      Enum.each(@names, fn name ->
        assert {:ok, include} = TS.get(name, :include)
        assert include.ast === name
      end)
    end

    test "rejects unknown template types" do
      assert_raise FunctionClauseError, fn -> TS.load(%{}, :foobarbaz) end
    end
  end

  describe "put/3" do
    test "puts/updates single template" do
      assert {:error, _} = TS.get("lorem", :template)
      TS.put("lorem", :template, @data["lorem"])
      assert {:ok, %Template{}} = TS.get("lorem", :template)
    end

    test "rejects unknown template types" do
      assert_raise FunctionClauseError, fn ->
        TS.put("lorem", :foobarbaz, @data["lorem"])
      end
    end
  end

  describe "reset/0" do
    test "resets the template storage to the initial state" do
      TS.load(@data, :template)
      TS.load(@data, :include)
      TS.reset()

      expected_state = %{template: %{}, include: %{}}
      real_state = :sys.get_state(TS)

      assert expected_state === real_state
    end
  end
end
