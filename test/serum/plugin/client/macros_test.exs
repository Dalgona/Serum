defmodule Serum.Plugin.Client.MacrosTest do
  use Serum.Case, async: true

  require Serum.Plugin.Client.Macros, as: Macros

  describe "interface/2" do
    test "can expand :action type interface" do
      spec_expr = quote(do: foo(bar :: binary()) :: Result.t({}))
      ast = quote(do: Macros.interface(:action, unquote(spec_expr)))
      generated_code = ast |> Macro.expand(__ENV__) |> Macro.to_string()

      assert generated_code =~ "@spec(foo(bar :: binary()) :: Result.t({}))"
      assert generated_code =~ "def(foo(bar)) do"
      assert generated_code =~ "call_action(:foo, [bar])"
    end

    test "can expand :function type interface" do
      spec_expr = quote(do: foo(bar :: binary()) :: Result.t(binary()))
      ast = quote(do: Macros.interface(:function, unquote(spec_expr)))
      generated_code = ast |> Macro.expand(__ENV__) |> Macro.to_string()

      assert generated_code =~ "@spec(foo(bar :: binary()) :: Result.t(binary()))"
      assert generated_code =~ "def(foo(bar)) do"
      assert generated_code =~ "call_function(:foo, [bar])"
    end
  end
end
