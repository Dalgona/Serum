defmodule Serum.Build.FragmentGeneratorTest do
  use Serum.Case
  require Serum.TestHelper
  alias Serum.Build.FragmentGenerator
  alias Serum.GlobalBindings
  alias Serum.Template.Storage, as: TS

  setup_all do
    project = build(:project)

    {:ok,
     [
       pages: build_list(3, :page, project: project),
       posts: build_list(3, :post, project: project),
       lists: build_list(3, :post_list, project: project),
       state: build(:global_bindings)
     ]}
  end

  setup do
    on_exit(fn ->
      Agent.update(GlobalBindings, fn _ -> {%{}, []} end)
      TS.reset()
    end)
  end

  describe "to_fragment/2" do
    test "generates fragments from fragment sources", ctx do
      load_templates()
      GlobalBindings.load(ctx.state)

      processed = %{
        pages: ctx.pages,
        posts: ctx.posts,
        lists: ctx.lists
      }

      {:ok, fragments} = FragmentGenerator.to_fragment(processed)
      actual_count = length(ctx.pages) + length(ctx.posts) + length(ctx.lists)

      assert length(fragments) === actual_count
    end

    test "fails with bad templates", ctx do
      load_templates(break: true)
      GlobalBindings.load(ctx.state)

      processed = %{
        pages: ctx.pages,
        posts: ctx.posts,
        lists: ctx.lists
      }

      assert {:error, _} = FragmentGenerator.to_fragment(processed)
    end

    test "fails when pages use custom templates which are unavailable", ctx do
      [page | pages] = ctx.pages
      bad_page = %{page | template: "foobarbaz"}

      load_templates()
      GlobalBindings.load(ctx.state)

      processed = %{
        pages: [bad_page | pages],
        posts: [],
        lists: []
      }

      assert {:error, _} = FragmentGenerator.to_fragment(processed)
    end

    test "fails when posts use custom templates which are unavailable", ctx do
      [post | posts] = ctx.posts
      bad_post = %{post | template: "foobarbaz"}

      load_templates()
      GlobalBindings.load(ctx.state)

      processed = %{
        pages: [],
        posts: [bad_post | posts],
        lists: []
      }

      assert {:error, _} = FragmentGenerator.to_fragment(processed)
    end
  end
end
