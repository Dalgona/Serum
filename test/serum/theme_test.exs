defmodule Serum.ThemeTest do
  use ExUnit.Case
  require Serum.TestHelper
  import Serum.TestHelper, only: :macros
  alias Serum.Theme

  "theme_modules/*.ex"
  |> fixture()
  |> Path.wildcard()
  |> Enum.each(&Code.require_file/1)

  describe "get_info/1" do
    test "successfully loads info for valid theme module" do
      assert {:ok, info} = Theme.get_info(Serum.DummyTheme)

      expected = %{
        name: "Dummy Theme",
        description: "This is a dummy theme for testing.",
        author: "John Doe",
        legal: "Copyleft",
        version: Version.parse!("0.1.0")
      }

      assert expected === info
    end

    test "fails to load due to non-existent callbacks" do
      assert {:error, _} = Theme.get_info(Serum.NotATheme)
    end

    test "fails to load due to the bad version format" do
      assert {:error, _} = Theme.get_info(Serum.BadVersionTheme)
    end

    test "fails to load due to the bad requirement format" do
      assert {:error, _} = Theme.get_info(Serum.BadRequirementTheme)
    end

    test "prints warning if Serum requirement does not match" do
      output =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          assert {:ok, _} = Theme.get_info(Serum.IncompatibleTheme)
        end)

      assert String.contains?(output, "not compatible")
    end

    test "does nothing if the theme module is nil" do
      assert {:ok, nil} === Theme.get_info(nil)
    end
  end
end
