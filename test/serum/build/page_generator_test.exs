defmodule Serum.Build.PageGeneratorTest do
  use Serum.Case
  require Serum.TestHelper
  alias Serum.Build.PageGenerator
  alias Serum.GlobalBindings
  alias Serum.Template.Storage, as: TS
  alias Serum.V2.Error

  setup_all do
    project = build(:project)
    list = build(:post_list, project: project)
    posts = list.posts
    pages = build_list(3, :page)

    fragments =
      [list, pages, posts]
      |> List.flatten()
      |> Enum.map(&build(:fragment, from: &1))

    {:ok, [fragments: fragments, state: build(:global_bindings)]}
  end

  setup do
    on_exit(fn ->
      Agent.update(GlobalBindings, fn _ -> {%{}, []} end)
      TS.reset()
    end)
  end

  describe "run/2" do
    test "completes with a good base template", ctx do
      load_templates()
      GlobalBindings.load(ctx.state)

      assert {:ok, files} = PageGenerator.run(ctx.fragments)
      assert length(files) === length(ctx.fragments)
    end

    test "fails with a bad base template", ctx do
      load_templates(break: true)
      GlobalBindings.load(ctx.state)

      assert {:error, %Error{caused_by: errors}} = PageGenerator.run(ctx.fragments)
      assert not Enum.empty?(errors)
    end
  end
end
