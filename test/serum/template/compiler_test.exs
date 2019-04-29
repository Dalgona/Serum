defmodule Serum.Template.CompilerTest do
  use ExUnit.Case, async: true
  require Serum.TestHelper
  import Serum.TestHelper, only: :macros
  alias Serum.Template
  alias Serum.Template.Compiler, as: TC

  describe "compile_files/2" do
    test "_compile includable templates" do
      file = %Serum.File{src: fixture("templates/good.html.eex")}
      {:ok, file} = mute_stdio(do: Serum.File.read(file))
      {:ok, %{"good" => %Template{} = template}} = TC.compile_files([file], :include)
      {output, _} = Code.eval_quoted(template.ast)

      assert String.contains?(output, "Hello, world!")
    end

    test "_compile templates" do
      key = "good-using-helpers"
      file = %Serum.File{src: fixture("templates/#{key}.html.eex")}
      {:ok, file} = mute_stdio(do: Serum.File.read(file))
      {:ok, %{^key => %Template{} = template}} = TC.compile_files([file], :template)
      assigns = [site: %{base_url: "/test_site/"}]
      {output, _} = Code.eval_quoted(template.ast, assigns: assigns)

      assert String.contains?(output, "/test_site/index.html")
    end

    test "_handle ill-formed templates" do
      files =
        mute_stdio do
          fixture("templates")
          |> Path.join("bad-*.html.eex")
          |> Path.wildcard()
          |> Enum.map(&%Serum.File{src: &1})
          |> Enum.map(&Serum.File.read/1)
          |> Enum.map(fn {:ok, file} -> file end)
        end

      {:error, {_, errors}} = TC.compile_files(files, :template)

      assert length(errors) === length(files)
    end

    test "compile includable templates" do
      file = %Serum.File{src: fixture("templates/good.html.eex")}
      {:ok, file} = mute_stdio(do: Serum.File.read(file))
      {:ok, includes} = TC.compile_files([file], type: :include)
      {output, _} = Code.eval_quoted(includes["good"].template.ast)

      assert String.contains?(output, "Hello, world!")

      tc_options = [type: :template, includes: includes]
      key = "good-using-includes"
      file = %Serum.File{src: fixture("templates/#{key}.html.eex")}
      {:ok, file} = mute_stdio(do: Serum.File.read(file))
      {:ok, %{^key => template}} = TC.compile_files([file], tc_options)
      {output, _} = Code.eval_quoted(template)

      assert String.contains?(output, "Include Test")
      assert String.contains?(output, "Hello, world!")
    end

    test "compile templates" do
      key = "good-using-helpers"
      file = %Serum.File{src: fixture("templates/#{key}.html.eex")}
      {:ok, file} = mute_stdio(do: Serum.File.read(file))
      {:ok, %{^key => template}} = TC.compile_files([file], type: :template)
      assigns = [site: %{base_url: "/test_site/"}]
      {output, _} = Code.eval_quoted(template.ast, assigns: assigns)

      assert String.contains?(output, "/test_site/index.html")
    end

    test "handle ill-formed templates" do
      files =
        mute_stdio do
          fixture("templates")
          |> Path.join("bad-*.html.eex")
          |> Path.wildcard()
          |> Enum.map(&%Serum.File{src: &1})
          |> Enum.map(&Serum.File.read/1)
          |> Enum.map(fn {:ok, file} -> file end)
        end

      {:error, {_, errors}} = TC.compile_files(files, type: :template)

      assert length(errors) === length(files)
    end
  end
end
