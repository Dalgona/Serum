defmodule Serum.Project.LoaderTest do
  use ExUnit.Case, async: true
  require Serum.TestHelper
  import Serum.TestHelper, only: :macros
  alias Serum.Error
  alias Serum.Project
  alias Serum.Project.Loader, as: ProjectLoader

  setup_all do
    {:ok, [dest: "/path/to/dest/"]}
  end

  describe "load/2" do
    test "loads valid serum.exs file", ctx do
      src = fixture("proj/good/")
      assert {:ok, %Project{}} = ProjectLoader.load(src, ctx.dest)
    end

    test "fails when serum.exs does not exist", ctx do
      src = fixture("proj/non-existent")
      file = Path.join(src, "serum.exs")
      {:error, %Error{} = error} = ProjectLoader.load(src, ctx.dest)

      assert error.file.src === file
      assert error.message.reason === :enoent
    end

    test "fails when serum.exs fails to compile", ctx do
      src = fixture("proj/bad-compile-error")
      file = Path.join(src, "serum.exs")
      {:error, %Error{} = error} = ProjectLoader.load(src, ctx.dest)

      assert error.file.src === file
    end

    test "fails when serum.exs fails to evaluate", ctx do
      src = fixture("proj/bad-eval-error")
      file = Path.join(src, "serum.exs")
      {:error, %Error{} = error} = ProjectLoader.load(src, ctx.dest)

      assert error.file.src === file
    end

    test "fails when serum.exs has validation errors", ctx do
      src = fixture("proj/bad-invalid")
      {:error, %Error{caused_by: errors}} = ProjectLoader.load(src, ctx.dest)

      assert length(errors) === 5
    end
  end
end
