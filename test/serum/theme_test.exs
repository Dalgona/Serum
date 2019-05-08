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

  describe "get_includes/1" do
    test "successfully retirves a list of paths" do
      assert {:ok, paths} = Theme.get_includes(Serum.DummyTheme)

      expected_paths = [
        "/foo/bar/includes/nav.html.eex",
        "/foo/bar/includes/sidebar.html.eex"
      ]

      assert paths === expected_paths
    end

    test "ignores invalid items" do
      assert {:ok, paths} = Theme.get_includes(Serum.WeirdTheme)

      expected_paths = [
        "/foo/bar/includes/nav.html.eex",
        "/foo/bar/includes/sidebar.html.eex"
      ]

      assert paths === expected_paths
    end

    test "may fail in some cases" do
      assert {:error, msg} = Theme.get_includes(Serum.FailingTheme)
      assert String.contains?(msg, "test error from get_includes/0")
    end

    test "does nothing if the theme module is nil" do
      assert {:ok, []} === Theme.get_includes(nil)
    end
  end

  describe "get_templates/1" do
    test "successfully retirves a list of paths" do
      assert {:ok, paths} = Theme.get_templates(Serum.DummyTheme)

      expected_paths = [
        "/foo/bar/templates/base.html.eex",
        "/foo/bar/templates/list.html.eex",
        "/foo/bar/templates/post.html.eex"
      ]

      assert paths === expected_paths
    end

    test "ignores invalid items" do
      assert {:ok, paths} = Theme.get_templates(Serum.WeirdTheme)

      expected_paths = [
        "/foo/bar/templates/base.html.eex",
        "/foo/bar/templates/list.html.eex",
        "/foo/bar/templates/post.html.eex"
      ]

      assert paths === expected_paths
    end

    test "may fail in some cases" do
      assert {:error, msg} = Theme.get_templates(Serum.FailingTheme)
      assert String.contains?(msg, "test error from get_templates/0")
    end

    test "does nothing if the theme module is nil" do
      assert {:ok, []} === Theme.get_templates(nil)
    end
  end

  describe "get_assets/1" do
    test "successfully retrieves a path" do
      uniq = Base.url_encode64(:crypto.strong_rand_bytes(6))
      tmp_path = Path.expand("serum_test_" <> uniq, System.tmp_dir!())
      {:ok, agent} = Agent.start_link(fn -> tmp_path end, name: Serum.TestAgent)

      File.mkdir_p!(tmp_path)
      assert {:ok, tmp_path} === Theme.get_assets(Serum.DummyTheme)
      File.rm_rf!(tmp_path)

      :ok = Agent.stop(agent)
    end

    test "fails if the returned path is not a directory" do
      uniq = Base.url_encode64(:crypto.strong_rand_bytes(6))
      tmp_path = Path.expand("serum_test_" <> uniq, System.tmp_dir!())
      {:ok, agent} = Agent.start_link(fn -> tmp_path end, name: Serum.TestAgent)
      expected = {:error, {:enotdir, tmp_path, 0}}

      File.touch!(tmp_path)
      assert expected === Theme.get_assets(Serum.WeirdTheme)
      File.rm_rf!(tmp_path)

      :ok = Agent.stop(agent)
    end

    test "may also fail in some other cases" do
      assert {:error, msg} = Theme.get_assets(Serum.FailingTheme)
      assert String.contains?(msg, "test error from get_assets/0")
    end

    test "does nothing if the theme module is nil" do
      assert {:ok, nil} === Theme.get_assets(nil)
    end
  end
end
