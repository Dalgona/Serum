defmodule Serum.Template.CompilerTest do
  use Serum.Case, async: true
  require Serum.TestHelper
  alias Serum.Template.Compiler, as: TC
  alias Serum.Template.Storage, as: TS
  alias Serum.V2
  alias Serum.V2.Error

  setup do
    on_exit(fn -> TS.reset() end)
  end

  describe "compile_files/2" do
    test "compiles templates" do
      key = "good-using-helpers"
      file = %V2.File{src: fixture("templates/#{key}.html.eex")}
      {:ok, file} = V2.File.read(file)
      {:ok, %{^key => template}} = TC.compile_files([file], type: :template)
      assigns = [site: %{base_url: "/test_site/"}]
      {output, _} = Code.eval_quoted(template.ast, assigns: assigns)

      assert template.type === :template
      assert String.contains?(output, "/test_site/index.html")
    end

    test "handles ill-formed templates" do
      files =
        fixture("templates")
        |> Path.join("bad-*.html.eex")
        |> Path.wildcard()
        |> Enum.map(&%V2.File{src: &1})
        |> Enum.map(&V2.File.read/1)
        |> Enum.map(fn {:ok, file} -> file end)

      {:error, %Error{caused_by: errors}} = TC.compile_files(files, type: :template)

      assert length(errors) === length(files)
    end
  end
end
