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
      assert {:ok, %Project{}} = ProjectLoader.load(src, ctx.dest)
    end

    test "load non-existent file", ctx do
      src = fixture("proj/non-existent")
      file = Path.join(src, "serum.exs")
      assert {:error, {:enoent, ^file, 0}} = ProjectLoader.load(src, ctx.dest)
    end

    test "serum.exs compile-time error", ctx do
      src = fixture("proj/bad-compile-error")
      file = Path.join(src, "serum.exs")
      assert {:error, {_msg, ^file, _line}} = ProjectLoader.load(src, ctx.dest)
    end

    test "serum.exs eval-time error", ctx do
      src = fixture("proj/bad-eval-error")
      file = Path.join(src, "serum.exs")
      assert {:error, {_msg, ^file, _line}} = ProjectLoader.load(src, ctx.dest)
    end

    test "serum.exs validation error", ctx do
      src = fixture("proj/bad-invalid")
      assert {:error, {_, errors}} = ProjectLoader.load(src, ctx.dest)
      assert length(errors) === 5
    end
  end
end
