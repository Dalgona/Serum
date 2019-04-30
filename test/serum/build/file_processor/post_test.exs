defmodule Serum.Build.FileProcessor.PostTest do
  use ExUnit.Case, async: true
  require Serum.TestHelper
  import Serum.TestHelper, only: :macros
  alias Serum.Build.FileProcessor.Post, as: PostProcessor
  alias Serum.Project.Loader, as: ProjectLoader

  setup_all do
    {:ok, proj} = ProjectLoader.load(fixture("proj/good/"), "/path/to/dest/")

    {:ok, [proj: proj]}
  end

  describe "process_posts/2" do
    test "good post", ctx do
      {:ok, result} = process("posts/good-post.md", ctx.proj)
      {[post], [compact_post]} = result

      assert %{
               title: "Test Post",
               date: "2019-01-01",
               raw_date: {{2019, 1, 1}, {12, 34, 56}},
               tags: [%{name: "tag1"}, %{name: "tag2"}]
             } = post

      assert_compact(compact_post)
    end

    test "good, date without time", ctx do
      {:ok, result} = process("posts/good-alternative-date.md", ctx.proj)
      {[post], [compact_post]} = result

      assert %{
               title: "Test Post",
               date: "2019-01-01",
               raw_date: {{2019, 1, 1}, {0, 0, 0}},
               tags: [%{name: "tag3"}, %{name: "tag4"}]
             } = post

      assert_compact(compact_post)
    end

    test "good, without tags", ctx do
      {:ok, result} = process("posts/good-minimal-header.md", ctx.proj)
      {[post], [compact_post]} = result

      assert %{
               title: "Test Post",
               date: "2019-01-01",
               raw_date: {{2019, 1, 1}, {0, 0, 0}},
               tags: []
             } = post

      assert_compact(compact_post)
    end

    test "fail on bad posts", ctx do
      files =
        mute_stdio do
          fixture("posts")
          |> Path.join("bad-*.md")
          |> Path.wildcard()
          |> Enum.map(&%Serum.File{src: &1})
          |> Enum.map(&Serum.File.read/1)
          |> Enum.map(fn {:ok, file} -> file end)
        end

      {:error, {_, errors}} =
        mute_stdio do
          PostProcessor.process_posts(files, ctx.proj)
        end

      assert length(errors) === length(files)
    end
  end

  defp process(fixture_path, proj) do
    {:ok, file} =
      mute_stdio do
        Serum.File.read(%Serum.File{src: fixture(fixture_path)})
      end

    mute_stdio(do: PostProcessor.process_posts([file], proj))
  end

  defp assert_compact(map) do
    refute map[:__struct__]
    refute map[:file]
    refute map[:html]
    refute map[:output]
    assert map.type === :post
  end
end
