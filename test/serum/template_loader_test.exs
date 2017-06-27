defmodule TemplateLoaderTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Serum.TemplateLoader

  describe "load_templates/1" do
    # load_templates(state) => Result(new_state)
    #   loads {base,list,page,post}.html.eex from <states.src>templates/
    #   directory, compiles and preprocesses them with compile_templates/2,
    #   and returns the updated state object if everything is done successfully.
    #   The state object must have valid .src and .project_info.base_url key.
    #   The returned state object must have .templates, which looks like this:
    #     %{"base" => <AST>, "list" => <AST>, "page" => <AST>, "post" => <AST>}
    #
    # Error Conditions:
    #   * <states.src>/templates directory does not exist,
    #     or at least one required template files are missing in that dir.
    #   * Fails to read at least one required template files.
    #   * compile_templates/2 returns at least one error.
    # Since multiple errors may occur, this function should return an aggregated
    # error object on failure.

    test "typical usage" do
      s = Map.put state(), :src, get_priv("load_templates/typical/")
      silent_load_templates s
      receive do
        {:ok, _} -> :ok
        _ -> flunk "received unexpected message"
      end
    end

    test "templates dir is missing" do
      s = Map.put state(), :src, get_priv("load_templates/missing_dir/")
      silent_load_templates s
      receive do
        {:error, _, _} -> :ok
        _ -> flunk "received unexpected message"
      end
    end

    test "fails to read some templates" do
      s = Map.put state(), :src, get_priv("load_templates/missing_some/")
      silent_load_templates s
      receive do
        {:error, _, _} -> :ok
        _ -> flunk "received unexpected message"
      end
    end

    test "erroneous templates" do
      s = Map.put state(), :src, get_priv("load_templates/erroneous/")
      silent_load_templates s
      receive do
        {:error, _, _} -> :ok
        _ -> flunk "received unexpected message"
      end
    end
  end

  describe "load_includes/1" do
    # load_includes(state) => Result(new_state)
    #   Scans <state.src>includes/ directory for any .html.eex file, loads the
    #   scanned files, compiles, preprocesses, and renders them into HTML stubs.
    #   And finally returns the updated state object. The original state object
    #   must have .src, .project_info.base_url, and .site_ctx.
    #
    #   This function should not return an error object if the directory is
    #   missing. Instead, it should return a new state object with an empty map
    #   added.
    #
    # Error Conditions:
    #   * Errors while compiling template files into ASTs.
    #   * Errors while eval-ing ASTs into HTML stubs.

    test "no includes dir" do
      s = Map.put state(), :src, get_priv("load_includes/missing_dir/")
      silent_load_includes s
      receive do
        {:ok, s2} ->
          assert s2.includes == %{}
        _ -> flunk "received unexpected message"
      end
    end

    test "empty includes dir" do
      s = Map.put state(), :src, get_priv("load_includes/empty_dir/")
      silent_load_includes s
      receive do
        {:ok, s2} ->
          assert s2.includes == %{}
        _ -> flunk "received unexpected message"
      end
    end

    test "everything looks good" do
      s = Map.put state(), :src, get_priv("load_includes/good/")
      silent_load_includes s
      receive do
        {:ok, s2} ->
          assert s2.includes["test"] == "Hello, world!\n"
          assert s2.includes["test2"] == "[10][20][30]\n"
        _ -> flunk "received unexpected message"
      end
    end

    test "some has compile-time problems" do
      s = Map.put state(), :src, get_priv("load_includes/compile_err/")
      silent_load_includes s
      receive do
        {:error, _, _} -> :ok
        _ -> flunk "received unexpected message"
      end
    end

    test "some has eval-time problems" do
      s = Map.put state(), :src, get_priv("load_includes/eval_err/")
      silent_load_includes s
      receive do
        {:error, _, _} -> :ok
        _ -> flunk "received unexpected message"
      end
    end
  end

  describe "compile_template/2" do
    # compile_template(data, state) => Result(compiled_ast)
    #   With information provided by `state`, compiles `data` (which is EEx
    #   string), preprocesses template helper macros, and returns the processed
    #   Elixir AST.
    #
    # List of helper macros:
    #   base()        => state.base_url
    #   base(path)    => state.base_url <> path
    #   post(name)    => state.base_url <> "posts/" <> name <> ".html"
    #   page(name)    => state.base_url <> name <> ".html"
    #   asset(path)   => state.base_url <> "assets/" <> path
    #   include(name) => (contents of html stub)
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

    test "expanding include/1" do
      data = ~s(<div><%= include "test" %></div>)
      {:ok, ast} = compile_template data, state()
      {evaled, _} = Code.eval_quoted ast
      assert "<div><span><b>Hello, world!</b></span></div>" == evaled
    end

    test "expanding include/1 with non-existent key" do
      data = ~s(<div><%= include "heroes_of_the_storm" %></div>)
      capture_io :stderr, fn -> send self(), compile_template(data, state()) end
      receive do
        {:ok, ast} ->
          {evaled, _} = Code.eval_quoted ast
          assert "<div></div>" == evaled
        _ ->
          flunk "received unexpected message"
      end
    end

    # TESTS FOR ERROR HANDLING
    # Note: Handling undefined function error while eval-ing the template
    #       is the responsibility of Serum.Renderer module.

    test "missing closing eex delimiter" do
      data = "<%= 42"
      result = compile_template data, state()
      refute :ok == elem(result, 0)
    end

    test "syntax error type 1" do
      data = "<%= [ %>"
      result = compile_template data, state()
      refute :ok == elem(result, 0)
    end

    test "syntax error type 2" do
      data = "<%= *323456 %>"
      result = compile_template data, state()
      refute :ok == elem(result, 0)
    end

    test "syntax error type 3" do
      data = "<%= for x <- [1, 2, 3] do %>"
      result = compile_template data, state()
      refute :ok == elem(result, 0)
    end
  end

  defp get_priv(path) do
    priv = :serum |> :code.priv_dir |> IO.iodata_to_binary
    priv <> "/template_loader_test/" <> path
  end

  defp silent_load_templates(s) do
    capture_io :stderr, fn ->
      capture_io fn ->
        result = load_templates s
        send self(), result
      end
    end
  end

  defp silent_load_includes(s) do
    capture_io :stderr, fn ->
      capture_io fn ->
        result = load_includes s
        send self(), result
      end
    end
  end

  #
  # DATA
  #

  defp state, do: %{
    project_info: %{base_url: "/test_base/"},
    includes: %{
      "test" => "<span><b>Hello, world!</b></span>"
    },
    site_ctx: [hello: "world", list: [10, 20, 30]]
  }
end
