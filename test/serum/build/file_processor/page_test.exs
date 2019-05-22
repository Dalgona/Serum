defmodule Serum.Build.FileProcessor.PageTest do
  use ExUnit.Case, async: true
  require Serum.TestHelper
  import Serum.Build.FileProcessor.Page
  import Serum.TestHelper, only: :macros
  alias Serum.Project.Loader, as: ProjectLoader
  alias Serum.Template
  alias Serum.Template.Compiler, as: TC

  setup_all do
    {:ok, proj} = ProjectLoader.load(fixture("proj/good/"), "/path/to/dest/")
    {:ok, ast} = TC.compile_string(~S(<%= "Hello, world!" %>), type: :template)
    includes = %{"test" => Template.new(ast, :template, "test.html.eex")}

    {:ok, [proj: proj, includes: includes]}
  end

  describe "preprocess_pages/2" do
    test "supported file types", %{proj: proj, includes: includes} do
      page_files =
        [
          "pages/good-md.md",
          "pages/good-html.html",
          "pages/good-eex.html.eex"
        ]
        |> Enum.map(&fixture/1)
        |> Enum.map(&%Serum.File{src: &1})
        |> Enum.map(&Serum.File.read/1)
        |> Enum.map(fn {:ok, file} -> file end)

      {:ok, {pages, compact_pages}} = preprocess_pages(page_files, proj)
      {:ok, pages} = process_pages(pages, includes, proj)
      [page1, page2, page3] = pages

      assert %{
               title: "Test Markdown Page",
               label: "test-md",
               group: "test",
               order: 1,
               type: ".md"
             } = page1

      assert %{
               title: "Test HTML Page",
               label: "test-html",
               group: "test",
               order: 2,
               type: ".html"
             } = page2

      assert %{
               title: "Test EEx Page",
               label: "test-eex",
               group: "test",
               order: 3,
               type: ".html.eex"
             } = page3

      assert Enum.all?(pages, &String.contains?(&1.data, "Hello, world!"))

      Enum.each(compact_pages, fn map ->
        refute map[:__struct__]
        refute map[:data]
        refute map[:file]
        refute map[:output]
        assert map.type === :page
      end)
    end

    test "use default label", ctx do
      file = %Serum.File{src: fixture("pages/good-minimal-header.md")}
      {:ok, file} = Serum.File.read(file)
      {:ok, {[page], [compact_page]}} = preprocess_pages([file], ctx.proj)

      assert page.label === "Test Page"
      assert compact_page.label === "Test Page"
    end

    test "fail on pages with bad headers", ctx do
      files =
        fixture("pages")
        |> Path.join("bad-*.md")
        |> Path.wildcard()
        |> Enum.map(&%Serum.File{src: &1})
        |> Enum.map(&Serum.File.read/1)
        |> Enum.map(fn {:ok, file} -> file end)

      {:error, {_, errors}} = preprocess_pages(files, ctx.proj)

      assert length(errors) === length(files)
    end

    test "fail on bad EEx pages", ctx do
      files =
        fixture("pages")
        |> Path.join("bad-*.html.eex")
        |> Path.wildcard()
        |> Enum.map(&%Serum.File{src: &1})
        |> Enum.map(&Serum.File.read/1)
        |> Enum.map(fn {:ok, file} -> file end)

      {:ok, {pages, _}} = preprocess_pages(files, ctx.proj)
      {:error, {_, errors}} = process_pages(pages, ctx.includes, ctx.proj)

      assert length(errors) === length(files)
    end
  end
end
