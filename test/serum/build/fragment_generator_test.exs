defmodule Serum.Build.FragmentGeneratorTest do
  use ExUnit.Case
  require Serum.TestHelper
  import Serum.TestHelper, only: :macros
  alias Serum.Build.FragmentGenerator
  alias Serum.GlobalBindings

  setup_all do
    {pages, _} = Code.eval_file(fixture("precompiled/good-pages.exs"))
    {posts, _} = Code.eval_file(fixture("precompiled/good-posts.exs"))
    {lists, _} = Code.eval_file(fixture("precompiled/good-lists.exs"))
    {state, _} = Code.eval_file(fixture("precompiled/good-gb.exs"))

    {:ok, [pages: pages, posts: posts, lists: lists, state: state]}
  end

  setup do
    on_exit(fn ->
      Agent.update(GlobalBindings, fn _ -> {%{}, []} end)
    end)
  end

  describe "to_fragment/2" do
    test "all went well", ctx do
      {templates, _} = Code.eval_file(fixture("precompiled/good-templates.exs"))

      GlobalBindings.load(ctx.state)

      processed = %{
        pages: ctx.pages,
        posts: ctx.posts,
        lists: ctx.lists,
        templates: templates,
        includes: []
      }

      {:ok, fragments} = FragmentGenerator.to_fragment(processed)
      actual_count = length(ctx.pages) + length(ctx.posts) + length(ctx.lists)

      assert length(fragments) === actual_count
    end

    test "failed due to bad templates", ctx do
      {templates, _} = Code.eval_file(fixture("precompiled/bad-templates.exs"))

      GlobalBindings.load(ctx.state)

      processed = %{
        pages: ctx.pages,
        posts: ctx.posts,
        lists: ctx.lists,
        templates: templates,
        includes: []
      }

      assert {:error, _} = FragmentGenerator.to_fragment(processed)
    end

    test "fails when pages use custom templates which are unavailable", ctx do
      GlobalBindings.load(ctx.state)

      {templates, _} = Code.eval_file(fixture("precompiled/good-templates.exs"))
      [page | pages] = ctx.pages
      bad_page = %{page | template: "foobarbaz"}

      processed = %{
        pages: [bad_page | pages],
        posts: [],
        lists: [],
        templates: templates,
        includes: []
      }

      assert {:error, _} = FragmentGenerator.to_fragment(processed)
    end

    test "fails when posts use custom templates which are unavailable", ctx do
      GlobalBindings.load(ctx.state)

      {templates, _} = Code.eval_file(fixture("precompiled/good-templates.exs"))
      [post | posts] = ctx.posts
      bad_post = %{post | template: "foobarbaz"}

      processed = %{
        pages: [],
        posts: [bad_post | posts],
        lists: [],
        templates: templates,
        includes: []
      }

      assert {:error, _} = FragmentGenerator.to_fragment(processed)
    end
  end
end
