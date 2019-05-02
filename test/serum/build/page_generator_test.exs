defmodule Serum.Build.PageGeneratorTest do
  use ExUnit.Case, async: true
  require Serum.TestHelper
  import Serum.TestHelper, only: :macros
  alias Serum.Build.PageGenerator
  alias Serum.GlobalBindings

  setup_all do
    {fragments, _} = Code.eval_file(fixture("precompiled/good-fragments.exs"))
    {good, _} = Code.eval_file(fixture("precompiled/good-templates.exs"))
    {bad, _} = Code.eval_file(fixture("precompiled/bad-templates.exs"))
    {state, _} = Code.eval_file(fixture("precompiled/good-gb.exs"))

    {:ok, [fragments: fragments, good: good["base"], bad: bad["base"], state: state]}
  end

  setup(do: on_exit(fn -> Agent.update(GlobalBindings, fn _ -> %{} end) end))

  describe "run/2" do
    test "good", ctx do
      GlobalBindings.load(ctx.state)

      assert {:ok, files} = run(ctx.fragments, ctx.good)
      assert length(files) === length(ctx.fragments)
    end

    test "bad base template", ctx do
      GlobalBindings.load(ctx.state)

      assert {:error, {_, _errors}} = run(ctx.fragments, ctx.bad)
    end
  end

  defp run(fragments, template) do
    mute_stdio(do: PageGenerator.run(fragments, template))
  end
end
