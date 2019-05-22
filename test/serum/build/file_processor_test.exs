defmodule Serum.Build.FileProcessorTest do
  use ExUnit.Case
  require Serum.TestHelper
  import Serum.TestHelper, only: :macros
  alias Serum.Build.FileProcessor
  alias Serum.GlobalBindings
  alias Serum.Project.Loader, as: ProjectLoader

  # Here we *roughly* test this module
  # as its individual steps are thoroughly tested by these modules:
  # - Serum.Build.PageTest
  # - Serum.Build.PostTest
  # - Serum.Build.PostListTest

  setup_all do
    {:ok, proj} = ProjectLoader.load(fixture("proj/good"), "/tmp/dest/")

    good_page_files =
      fixture("pages")
      |> Path.join("good-*.md")
      |> Path.wildcard()
      |> read_files()

    good_post_files =
      fixture("posts")
      |> Path.join("good-*.md")
      |> Path.wildcard()
      |> read_files()

    good_include_files = read_files([fixture("templates/good.html.eex")])

    good_template_files =
      read_files([
        fixture("templates/good-using-helpers.html.eex"),
        fixture("templates/good-using-includes.html.eex")
      ])

    good = %{
      pages: good_page_files,
      posts: good_post_files,
      includes: good_include_files,
      templates: good_template_files
    }

    bad_page_files =
      fixture("pages")
      |> Path.join("bad-*.*")
      |> Path.wildcard()
      |> read_files()

    bad_post_files =
      fixture("posts")
      |> Path.join("bad-*.md")
      |> Path.wildcard()
      |> read_files()

    bad_template_files =
      fixture("templates")
      |> Path.join("bad-*.html.eex")
      |> Path.wildcard()
      |> read_files()

    bad = %{
      pages: bad_page_files,
      posts: bad_post_files,
      includes: [],
      templates: bad_template_files
    }

    {:ok, [good: good, bad: bad, proj: proj]}
  end

  setup(do: on_exit(fn -> Agent.update(GlobalBindings, fn _ -> {%{}, []} end) end))

  describe "process_files/2" do
    test "everything went all", ctx do
      assert {:ok, processed} = FileProcessor.process_files(ctx.good, ctx.proj)
    end

    test "bad templates", ctx do
      files = %{ctx.good | includes: [], templates: ctx.bad.templates}

      assert {:error, {_, errors}} = FileProcessor.process_files(files, ctx.proj)

      assert Enum.all?(errors, fn {:error, {_, f, _}} ->
               String.contains?(f, ".html.eex")
             end)
    end

    test "bad pages", ctx do
      files = %{ctx.good | pages: ctx.bad.pages}

      assert {:error, {_, errors}} = FileProcessor.process_files(files, ctx.proj)

      assert Enum.all?(errors, fn {:error, {_, f, _}} ->
               String.contains?(f, "pages")
             end)
    end

    test "bad posts", ctx do
      files = %{ctx.good | posts: ctx.bad.posts}

      assert {:error, {_, errors}} = FileProcessor.process_files(files, ctx.proj)

      assert Enum.all?(errors, fn {:error, {_, f, _}} ->
               String.contains?(f, "posts")
             end)
    end
  end

  defp read_files(paths) do
    paths
    |> Enum.map(&%Serum.File{src: &1})
    |> Enum.map(&Serum.File.read/1)
    |> Enum.map(fn {:ok, file} -> file end)
  end
end
