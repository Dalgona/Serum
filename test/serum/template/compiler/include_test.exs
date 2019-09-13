defmodule Serum.Template.Compiler.IncludeTest do
  use ExUnit.Case, async: true
  alias Serum.Template.Compiler.Include
  alias Serum.Template.Storage, as: TS

  setup_all do
    TS.load(includes(), :include)
  end

  describe "expand/1" do
    test "does not do anything with templates without include/2 call" do
      ast = EEx.compile_string("Hello, <%= :world %>!")
      {:ok, new_ast} = Include.expand(ast)

      assert ast === new_ast
    end

    test "expands simple include/2 macros" do
      ast = EEx.compile_string("[<%= include(\"simple\") %>]")
      {:ok, new_ast} = Include.expand(ast)
      {rendered, _} = Code.eval_quoted(new_ast)

      assert rendered === "[Hello, world!]"
    end

    test "expands nested include/2 macros" do
      ast = quote(do: include("nested_1"))
      {:ok, new_ast} = Include.expand(ast)
      {rendered, _} = Code.eval_quoted(new_ast)

      assert rendered === "Nested1 Nested2"
    end

    test "fails with non-existent includes" do
      ast = quote(do: include("foobarbaz"))
      {:ct_error, msg, _} = Include.expand(ast)

      assert String.contains?(msg, "foobarbaz")
    end

    test "fails when nested includes have cycles - simple" do
      ast = quote(do: include("simple_cycle"))
      {:ct_error, msg, _} = Include.expand(ast)

      assert msg =~ "simple_cycle"
    end

    test "fails when nested includes have cycles - deep" do
      ast = quote(do: include("deep_cycle_1"))
      {:ct_error, msg, _} = Include.expand(ast)

      1..3
      |> Enum.map(&"deep_cycle_#{&1}")
      |> Enum.each(fn name -> assert msg =~ name end)
    end
  end

  include_sources =
    [
      {"simple", "Hello, world!"},
      {"nested_1", quote(do: "Nested1 " <> include("nested_2"))},
      {"nested_2", "Nested2"},
      {"simple_cycle", quote(do: include("simple_cycle"))},
      {"deep_cycle_1", quote(do: include("deep_cycle_2"))},
      {"deep_cycle_2", quote(do: include("deep_cycle_3"))},
      {"deep_cycle_3", quote(do: include("deep_cycle_1"))}
    ]
    |> Enum.map(fn {name, ast} -> {name, %{name: name, ast: ast}} end)
    |> Enum.into(%{})

  defp includes, do: unquote(Macro.escape(include_sources))
end
