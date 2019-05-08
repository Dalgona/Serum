defmodule Serum.Project.LoaderTest do
  use ExUnit.Case, async: true
  require Serum.TestHelper
  import Serum.TestHelper, only: :macros
  alias Serum.Project
  alias Serum.Project.Loader, as: ProjectLoader

  setup_all do
    {:ok, [dest: "/path/to/dest/"]}
  end

  describe "load/2" do
    test "load normal serum.exs", ctx do
      src = fixture("proj/good/")
      assert {:ok, %Project{}} = load(src, ctx.dest)
    end

    test "load non-existent file", ctx do
      src = fixture("proj/non-existent")
      file = Path.join(src, "serum.exs")
      assert {:error, {:enoent, ^file, 0}} = load(src, ctx.dest)
    end

    test "serum.exs compile-time error", ctx do
      src = fixture("proj/bad-compile-error")
      file = Path.join(src, "serum.exs")
      assert {:error, {_msg, ^file, _line}} = load(src, ctx.dest)
    end

    test "serum.exs eval-time error", ctx do
      src = fixture("proj/bad-eval-error")
      file = Path.join(src, "serum.exs")
      assert {:error, {_msg, ^file, _line}} = load(src, ctx.dest)
    end

    test "serum.exs validation error", ctx do
      src = fixture("proj/bad-invalid")
      assert {:error, {_, errors}} = load(src, ctx.dest)
      assert length(errors) === 5
    end
  end

  defp load(src, dest), do: mute_stdio(do: ProjectLoader.load(src, dest))
end
