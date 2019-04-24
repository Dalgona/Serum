defmodule Serum.PageProcessTest do
  use ExUnit.Case, async: true
  require Serum.TestHelper
  import Serum.TestHelper, only: :macros
  alias Serum.Build.FileProcessor
  alias Serum.Project.Loader, as: ProjectLoader

  setup_all do
    {:ok, proj} = ProjectLoader.load(fixture("proj/good/"), "/path/to/dest/")

    {:ok, [proj: proj]}
  end

  describe "process_pages/2" do
    test "supported file types", ctx do
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

      {:ok, result} = FileProcessor.process_pages(page_files, ctx.proj)
      {[page1, page2, page3] = pages, compact_pages} = result

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

      {:ok, result} = FileProcessor.process_pages([file], ctx.proj)
      {[page], [compact_page]} = result

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

      {:error, {_, errors}} = FileProcessor.process_pages(files, ctx.proj)

      assert length(errors) === length(files)
    end
  end
end
