defmodule Serum.ThemeTest do
  use ExUnit.Case
  require Serum.TestHelper
  import Serum.TestHelper
  import Serum.Theme
  alias Serum.V2.Console

  "theme_modules/*.ex"
  |> fixture()
  |> Path.wildcard()
  |> Enum.each(&Code.require_file/1)

  setup_all do
    {:ok, io_opts} = Console.config()

    Console.config(mute_err: false)
    on_exit(fn -> Console.config(Keyword.new(io_opts)) end)

    :ok
  end

  describe "load/1" do
    test "successfully loads info for valid theme module" do
      assert {:ok, %Serum.Theme{} = info} = load(Serum.DummyTheme)

      expected = %Serum.Theme{
        module: Serum.DummyTheme,
        name: "Dummy Theme",
        description: "This is a dummy theme for testing.",
        author: "John Doe",
        legal: "Copyleft",
        version: Version.parse!("0.1.0")
      }

      assert expected === info
    end

    test "fails to load due to non-existent callbacks" do
      assert {:error, _} = load(Serum.NotATheme)
    end

    test "fails to load due to the bad version format" do
      assert {:error, _} = load(Serum.BadVersionTheme)
    end

    test "fails to load due to the bad requirement format" do
      assert {:error, _} = load(Serum.BadRequirementTheme)
    end

    test "prints warning if Serum requirement does not match" do
      output =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          assert {:ok, _} = load(Serum.IncompatibleTheme)
        end)

      assert String.contains?(output, "not compatible")
    end

    test "returns an empty struct if the theme module is nil" do
      assert {:ok, %Serum.Theme{}} === load(nil)
    end
  end

  describe "get_includes/1" do
    test "successfully retirves a list of paths" do
      {:ok, _theme} = load(Serum.DummyTheme)
      {:ok, %{} = paths} = get_includes()

      expected_paths = %{
        "nav" => "/foo/bar/includes/nav.html.eex",
        "sidebar" => "/foo/bar/includes/sidebar.html.eex"
      }

      assert paths === expected_paths
    end

    test "ignores invalid items" do
      {:ok, _theme} = load(Serum.WeirdTheme)
      {:ok, %{} = paths} = get_includes()

      expected_paths = %{
        "nav" => "/foo/bar/includes/nav.html.eex",
        "sidebar" => "/foo/bar/includes/sidebar.html.eex"
      }

      assert paths === expected_paths
    end

    test "fails if the returned value is not a list" do
      {:ok, _theme} = load(Serum.SuperWeirdTheme1)
      {:error, error} = get_includes()
      msg = to_string(error)

      assert msg =~ "Serum.SuperWeirdTheme1.get_includes"
      assert msg =~ inspect("/foo/bar/baz.html.eex")
    end

    test "fails if the returned list has non-binary values" do
      {:ok, _theme} = load(Serum.SuperWeirdTheme2)
      {:error, error} = get_includes()
      msg = to_string(error)

      assert msg =~ "Serum.SuperWeirdTheme2.get_includes"
      assert msg =~ inspect(42)
    end

    test "may also fail in some other cases" do
      {:ok, _theme} = load(Serum.FailingTheme)
      {:error, error} = get_includes()
      msg = to_string(error)

      assert msg =~ "test error from get_includes/0"
    end

    test "does nothing if the theme module is nil" do
      load(nil)
      assert {:ok, %{}} === get_includes()
    end
  end

  describe "get_templates/1" do
    test "successfully retirves a list of paths" do
      {:ok, _theme} = load(Serum.DummyTheme)
      {:ok, %{} = paths} = get_templates()

      expected_paths = %{
        "base" => "/foo/bar/templates/base.html.eex",
        "list" => "/foo/bar/templates/list.html.eex",
        "post" => "/foo/bar/templates/post.html.eex"
      }

      assert paths === expected_paths
    end

    test "ignores invalid items" do
      {:ok, _theme} = load(Serum.WeirdTheme)
      {:ok, %{} = paths} = get_templates()

      expected_paths = %{
        "base" => "/foo/bar/templates/base.html.eex",
        "list" => "/foo/bar/templates/list.html.eex",
        "post" => "/foo/bar/templates/post.html.eex",
        "magic" => "/foo/bar/templates/magic.html.eex"
      }

      assert paths === expected_paths
    end

    test "fails if the returned value is not a list" do
      load(Serum.SuperWeirdTheme1)
      {:error, error} = get_templates()
      msg = to_string(error)

      assert msg =~ "Serum.SuperWeirdTheme1.get_templates"
      assert msg =~ inspect("/foo/bar/baz.html.eex")
    end

    test "fails if the returned list has non-binary values" do
      load(Serum.SuperWeirdTheme2)
      {:error, error} = get_templates()
      msg = to_string(error)

      assert msg =~ "Serum.SuperWeirdTheme2.get_templates"
      assert msg =~ inspect(42)
    end

    test "may also fail in some other cases" do
      load(Serum.FailingTheme)
      {:error, error} = get_templates()
      msg = to_string(error)

      assert msg =~ "test error from get_templates/0"
    end

    test "does nothing if the theme module is nil" do
      load(nil)

      assert {:ok, %{}} === get_templates()
    end
  end

  describe "get_assets/1" do
    test "successfully retrieves a path" do
      tmp_path = get_tmp_dir("serum_test_")
      {:ok, agent} = Agent.start_link(fn -> tmp_path end, name: Serum.TestAgent)
      {:ok, _theme} = load(Serum.DummyTheme)

      File.mkdir_p!(tmp_path)
      assert {:ok, tmp_path} === get_assets()
      File.rm_rf!(tmp_path)

      :ok = Agent.stop(agent)
    end

    test "returns false to indicate that no asset will be copied" do
      {:ok, _theme} = load(Serum.EmptyTheme)

      assert {:ok, false} === get_assets()
    end

    test "fails if the returned path is not a directory" do
      tmp_path = get_tmp_dir("serum_test_")
      {:ok, agent} = Agent.start_link(fn -> tmp_path end, name: Serum.TestAgent)
      {:ok, _theme} = load(Serum.WeirdTheme)

      File.touch!(tmp_path)
      {:error, error} = get_assets()
      File.rm_rf!(tmp_path)

      assert error.message.reason === :enotdir

      :ok = Agent.stop(agent)
    end

    test "fails if the returned value is not a binary" do
      load(Serum.SuperWeirdTheme1)
      {:error, error} = get_assets()
      msg = to_string(error)

      assert msg =~ inspect(42)
    end

    test "may also fail in some other cases" do
      load(Serum.FailingTheme)
      {:error, error} = get_assets()
      msg = to_string(error)

      assert msg =~ "test error from get_assets/0"
    end

    test "does nothing if the theme module is nil" do
      load(nil)

      assert {:ok, false} === get_assets()
    end
  end
end
