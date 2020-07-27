defmodule Serum.Build.FileProcessorTest do
  use Serum.Case
  require Serum.TestHelper
  alias Serum.Build.FileProcessor
  alias Serum.GlobalBindings
  alias Serum.Project.Loader, as: ProjectLoader
  alias Serum.V2
  alias Serum.V2.BuildContext
  alias Serum.V2.Error

  # Here we *roughly* test this module
  # as its individual steps are thoroughly tested by these modules:
  # - Serum.Build.PageTest
  # - Serum.Build.PostTest
  # - Serum.Build.PostListTest

  setup_all do
    source_dir = fixture("proj/good")
    dest_dir = "/tmp/dest/"
    {:ok, proj} = ProjectLoader.load(source_dir)
    context = %BuildContext{project: proj, source_dir: source_dir, dest_dir: dest_dir}

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

    {:ok, [good: good, bad: bad, context: context]}
  end

  setup(do: on_exit(fn -> Agent.update(GlobalBindings, fn _ -> {%{}, []} end) end))

  describe "process_files/2" do
    test "processes valid source files", ctx do
      assert {:ok, processed} = FileProcessor.process_files(ctx.good, ctx.context)
    end

    test "fails with bad templates", ctx do
      files = %{ctx.good | includes: [], templates: ctx.bad.templates}
      {:error, %Error{caused_by: errors}} = FileProcessor.process_files(files, ctx.context)

      assert Enum.all?(errors, fn %Error{file: file} -> file.src =~ ~r/.html.eex$/ end)
    end

    test "fails with bad pages", ctx do
      files = %{ctx.good | pages: ctx.bad.pages}
      {:error, %Error{caused_by: errors}} = FileProcessor.process_files(files, ctx.context)

      assert Enum.all?(errors, fn %Error{file: file} -> file.src =~ "pages" end)
    end

    test "fails with bad posts", ctx do
      files = %{ctx.good | posts: ctx.bad.posts}
      {:error, %Error{caused_by: errors}} = FileProcessor.process_files(files, ctx.context)

      assert Enum.all?(errors, fn %Error{file: file} -> file.src =~ "posts" end)
    end
  end

  defp read_files(paths) do
    paths
    |> Enum.map(&%V2.File{src: &1})
    |> Enum.map(&V2.File.read/1)
    |> Enum.map(fn {:ok, file} -> file end)
  end
end
