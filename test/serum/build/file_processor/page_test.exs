defmodule Serum.Build.FileProcessor.PageTest do
  use ExUnit.Case
  require Serum.TestHelper
  import Serum.Build.FileProcessor.Page
  import Serum.TestHelper, only: :macros
  alias Serum.Error
  alias Serum.Project.Loader, as: ProjectLoader
  alias Serum.Template
  alias Serum.Template.Storage, as: TS

  setup_all do
    {:ok, proj} = ProjectLoader.load(fixture("proj/good/"), "/path/to/dest/")
    template = Template.new("Hello, world!", "test", :template, "test.html.eex")

    TS.load(%{"test" => template}, :include)
    on_exit(fn -> TS.reset() end)

    {:ok, [proj: proj]}
  end

  describe "preprocess_pages/2" do
    test "preprocesses markdown files", %{proj: proj} do
      file = read("pages/good-md.md")
      {:ok, {pages, [compact_page]}} = preprocess_pages([file], proj)
      {:ok, [page]} = process_pages(pages, proj)

      assert %{
               title: "Test Markdown Page",
               label: "test-md",
               group: "test",
               order: 1,
               type: "md"
             } = page

      assert page.data =~ "Hello, world!"

      validate_compact(compact_page)
    end

    test "preprocesses HTML-EEx files", %{proj: proj} do
      file = read("pages/good-html.html.eex")
      {:ok, {pages, [compact_page]}} = preprocess_pages([file], proj)
      {:ok, [page]} = process_pages(pages, proj)

      assert %{
               title: "Test HTML-EEx Page",
               label: "test-eex",
               group: "test",
               order: 3,
               type: "html"
             } = page

      assert page.data =~ "Hello, world!"

      validate_compact(compact_page)
    end

    test "fallbacks to the default label", ctx do
      file = %Serum.File{src: fixture("pages/good-minimal-header.md")}
      {:ok, file} = Serum.File.read(file)
      {:ok, {[page], [compact_page]}} = preprocess_pages([file], ctx.proj)

      assert page.label === "Test Page"
      assert compact_page.label === "Test Page"
    end

    test "fails on pages with bad headers", ctx do
      files =
        fixture("pages")
        |> Path.join("bad-*.md")
        |> Path.wildcard()
        |> Enum.map(&%Serum.File{src: &1})
        |> Enum.map(&Serum.File.read/1)
        |> Enum.map(fn {:ok, file} -> file end)

      {:error, %Error{caused_by: errors}} = preprocess_pages(files, ctx.proj)

      assert length(errors) === length(files)
    end

    test "fails on bad EEx pages", ctx do
      files =
        fixture("pages")
        |> Path.join("bad-*.html.eex")
        |> Path.wildcard()
        |> Enum.map(&%Serum.File{src: &1})
        |> Enum.map(&Serum.File.read/1)
        |> Enum.map(fn {:ok, file} -> file end)

      {:ok, {pages, _}} = preprocess_pages(files, ctx.proj)
      {:error, %Error{caused_by: errors}} = process_pages(pages, ctx.proj)

      assert length(errors) === length(files)
    end
  end

  defp read(path) do
    file = %Serum.File{src: fixture(path)}
    {:ok, file} = Serum.File.read(file)

    file
  end

  defp validate_compact(compact_page) do
    refute compact_page[:__struct__]
    refute compact_page[:data]
    refute compact_page[:file]
    refute compact_page[:output]
    assert compact_page.type === :page
  end
end
