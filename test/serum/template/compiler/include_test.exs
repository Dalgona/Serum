defmodule Serum.Template.Compiler.IncludeTest do
  use ExUnit.Case
  alias Serum.Result
  alias Serum.Template
  alias Serum.Template.Compiler.Include
  alias Serum.Template.Storage, as: TS

  setup_all do
    TS.load(includes(), :include)
  end

  describe "expand/1" do
    test "does not do anything with templates without include/2 call" do
      ast = EEx.compile_string("Hello, <%= :world %>!")
      template = make_template(ast)

      assert {:ok, new_template} = Include.expand(template)
      assert ast === new_template.ast
    end

    test "expands simple include/2 macros" do
      template = make_template(EEx.compile_string("[<%= include(\"simple\") %>]"))

      assert {:ok, new_template} = Include.expand(template)

      {rendered, _} = Code.eval_quoted(new_template.ast)

      assert rendered === "[Hello, world!]"
    end

    test "expands nested include/2 macros" do
      template = make_template(quote(do: include("nested_1")))

      assert {:ok, new_template} = Include.expand(template)

      {rendered, _} = Code.eval_quoted(new_template.ast)

      assert rendered === "Nested1 Nested2"
    end

    test "fails with non-existent includes" do
      template = make_template(quote(do: include("foobarbaz")))
      result = Include.expand(template)

      assert Result.get_message(result, 0) =~ "foobarbaz"
    end

    test "fails when nested includes have cycles - simple" do
      template = make_template(quote(do: include("simple_cycle")))
      result = Include.expand(template)

      assert Result.get_message(result, 0) =~ "simple_cycle"
    end

    test "fails when nested includes have cycles - deep" do
      template = make_template(quote(do: include("deep_cycle_1")))
      result_message = template |> Include.expand() |> Result.get_message(0)

      1..3
      |> Enum.map(&"deep_cycle_#{&1}")
      |> Enum.each(fn name -> assert result_message =~ name end)
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
    |> Enum.map(fn {name, ast} ->
      {name, Template.new(ast, name, :include, %Serum.File{src: name})}
    end)
    |> Enum.into(%{})

  defp includes, do: unquote(Macro.escape(include_sources))

  defp make_template(ast) do
    Template.new(ast, "test", :template, %Serum.File{src: "nofile"})
  end
end
