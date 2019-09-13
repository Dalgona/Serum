defmodule Serum.Build.PageGeneratorTest do
  use ExUnit.Case, async: true
  require Serum.TestHelper
  import Serum.TestHelper, only: :macros
  alias Serum.Build.PageGenerator
  alias Serum.GlobalBindings
  alias Serum.Template.Storage, as: TS

  setup_all do
    {fragments, _} = Code.eval_file(fixture("precompiled/good-fragments.exs"))
    {good, _} = Code.eval_file(fixture("precompiled/good-templates.exs"))
    {bad, _} = Code.eval_file(fixture("precompiled/bad-templates.exs"))
    {state, _} = Code.eval_file(fixture("precompiled/good-gb.exs"))

    {:ok, [fragments: fragments, good: good, bad: bad, state: state]}
  end

  setup do
    on_exit(fn ->
      Agent.update(GlobalBindings, fn _ -> {%{}, []} end)
      TS.reset()
    end)
  end

  describe "run/2" do
    test "completes with a good base template", ctx do
      TS.load(ctx.good, :template)
      GlobalBindings.load(ctx.state)

      assert {:ok, files} = PageGenerator.run(ctx.fragments)
      assert length(files) === length(ctx.fragments)
    end

    test "fails with a bad base template", ctx do
      TS.load(ctx.bad, :template)
      GlobalBindings.load(ctx.state)

      assert {:error, {_, _errors}} = PageGenerator.run(ctx.fragments)
    end
  end
end
