defmodule TemplateLoaderTest do
  use ExUnit.Case
  import Serum.TemplateLoader

  describe "load_templates/1" do
  end

  describe "load_includes/1" do
  end

  describe "compile_template/2" do
    # compile_template(data, state) => Result(compiled_ast)
    #   With information provided by `state`, compiles `data` (which is EEx
    #   string), preprocesses template helper macros, and returns the processed
    #   Elixir AST.
    #
    # List of helper macros:
    #   base()      => state.base_url
    #   base(path)  => state.base_url <> path
    #   post(name)  => state.base_url <> "posts/" <> name <> ".html"
    #   page(name)  => state.base_url <> name <> ".html"
    #   asset(path) => state.base_url <> "assets/" <> path
    #
    # Tests will be performed by evaluating the output AST and comparing with
    # expected string.

    test "an empty template" do
      data = ""
      {:ok, ast} = compile_template data, state()
      {evaled, _} = Code.eval_quoted ast
      assert "" == evaled
    end

    test "a very simple template" do
      data = "Heroes of the storm"
      {:ok, ast} = compile_template data, state()
      {evaled, _} = Code.eval_quoted ast
      assert "Heroes of the storm" == evaled
    end

    test "a simple template with an expression" do
      data = "<%= 6 * 7 %>"
      {:ok, ast} = compile_template data, state()
      {evaled, _} = Code.eval_quoted ast
      assert "42" == evaled
    end

    test "expanding base/0" do
      data = ~s[<a href="<%= base() %>">Home</a>]
      {:ok, ast} = compile_template data, state()
      {evaled, _} = Code.eval_quoted ast
      assert ~s(<a href="/test_base/">Home</a>) == evaled
    end

    test "expanding base/1" do
      data = ~s(<a href="<%= base "index.html" %>">Home</a>)
      {:ok, ast} = compile_template data, state()
      {evaled, _} = Code.eval_quoted ast
      assert ~s(<a href="/test_base/index.html">Home</a>) == evaled
    end

    test "expanding post/1" do
      data = ~s(<%= post "2017-06-26-test" %>)
      {:ok, ast} = compile_template data, state()
      {evaled, _} = Code.eval_quoted ast
      assert "/test_base/posts/2017-06-26-test.html" == evaled
    end

    test "expanding page/1" do
      data = ~s(<%= page "docs/pages" %>)
      {:ok, ast} = compile_template data, state()
      {evaled, _} = Code.eval_quoted ast
      assert "/test_base/docs/pages.html" == evaled
    end

    test "expanding asset/1" do
      data = ~s(<%= asset "css/style.css" %>)
      {:ok, ast} = compile_template data, state()
      {evaled, _} = Code.eval_quoted ast
      assert "/test_base/assets/css/style.css" == evaled
    end

    # TESTS FOR ERROR HANDLING

    @tag skip: "not implemented"

    test "SyntaxError" do
    end

    @tag skip: "not implemented"

    test "TokenMissingError" do
    end

    @tag skip: "not implemented"

    test "EEx.SyntaxError" do
    end
  end

  defp state, do: %{project_info: %{base_url: "/test_base/"}}
end