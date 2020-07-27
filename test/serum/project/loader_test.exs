defmodule Serum.Project.LoaderTest do
  use Serum.Case, async: true
  require Serum.TestHelper
  alias Serum.Project
  alias Serum.Project.Loader, as: ProjectLoader
  alias Serum.V2.Error

  describe "load/2" do
    test "loads valid serum.exs file" do
      src = fixture("proj/good/")
      assert {:ok, %Project{}} = ProjectLoader.load(src)
    end

    test "fails when serum.exs does not exist" do
      src = fixture("proj/non-existent")
      file = Path.join(src, "serum.exs")
      {:error, %Error{} = error} = ProjectLoader.load(src)

      assert error.file.src === file
      assert error.message.reason === :enoent
    end

    test "fails when serum.exs fails to compile" do
      src = fixture("proj/bad-compile-error")
      file = Path.join(src, "serum.exs")
      {:error, %Error{} = error} = ProjectLoader.load(src)

      assert error.file.src === file
    end

    test "fails when serum.exs fails to evaluate" do
      src = fixture("proj/bad-eval-error")
      file = Path.join(src, "serum.exs")
      {:error, %Error{} = error} = ProjectLoader.load(src)

      assert error.file.src === file
    end

    test "fails when serum.exs has validation errors" do
      src = fixture("proj/bad-invalid")
      {:error, %Error{caused_by: errors}} = ProjectLoader.load(src)

      assert length(errors) === 5
    end
  end
end
