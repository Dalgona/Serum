defmodule Serum.ThemeTest do
  use ExUnit.Case
  require Serum.TestHelper
  import Serum.TestHelper
  import Serum.Theme
  alias Serum.IOProxy

  "theme_modules/*.ex"
  |> fixture()
  |> Path.wildcard()
  |> Enum.each(&Code.require_file/1)

  setup_all do
    themes =
      [
        null: nil,
        dummy: Serum.DummyTheme,
        failing: Serum.FailingTheme,
        weird: Serum.WeirdTheme,
        super_weird_1: Serum.SuperWeirdTheme1,
        super_weird_2: Serum.SuperWeirdTheme2,
        empty: Serum.EmptyTheme
      ]
      |> Enum.map(fn {k, v} -> {k, load(v)} end)
      |> Enum.map(fn {k, {:ok, theme}} -> {k, theme} end)

    {:ok, io_opts} = IOProxy.config()

    IOProxy.config(mute_err: false)
    on_exit(fn -> IOProxy.config(Keyword.new(io_opts)) end)

    {:ok, themes}
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
    test "successfully retirves a list of paths", ctx do
      assert {:ok, %{} = paths} = get_includes(ctx.dummy)

      expected_paths = %{
        "nav" => "/foo/bar/includes/nav.html.eex",
        "sidebar" => "/foo/bar/includes/sidebar.html.eex"
      }

      assert paths === expected_paths
    end

    test "ignores invalid items", ctx do
      assert {:ok, %{} = paths} = get_includes(ctx.weird)

      expected_paths = %{
        "nav" => "/foo/bar/includes/nav.html.eex",
        "sidebar" => "/foo/bar/includes/sidebar.html.eex"
      }

      assert paths === expected_paths
    end

    test "fails if the returned value is not a list", ctx do
      assert {:error, msg} = get_includes(ctx.super_weird_1)
      assert String.contains?(msg, "Serum.SuperWeirdTheme1.get_includes")
      assert String.contains?(msg, inspect("/foo/bar/baz.html.eex"))
    end

    test "fails if the returned list has non-binary values", ctx do
      assert {:error, msg} = get_includes(ctx.super_weird_2)
      assert String.contains?(msg, "Serum.SuperWeirdTheme2.get_includes")
      assert String.contains?(msg, inspect(42))
    end

    test "may also fail in some other cases", ctx do
      assert {:error, msg} = get_includes(ctx.failing)
      assert String.contains?(msg, "test error from get_includes/0")
    end

    test "does nothing if the theme module is nil", ctx do
      assert {:ok, %{}} === get_includes(ctx.null)
    end
  end

  describe "get_templates/1" do
    test "successfully retirves a list of paths", ctx do
      assert {:ok, %{} = paths} = get_templates(ctx.dummy)

      expected_paths = %{
        "base" => "/foo/bar/templates/base.html.eex",
        "list" => "/foo/bar/templates/list.html.eex",
        "post" => "/foo/bar/templates/post.html.eex"
      }

      assert paths === expected_paths
    end

    test "ignores invalid items", ctx do
      assert {:ok, %{} = paths} = get_templates(ctx.weird)

      expected_paths = %{
        "base" => "/foo/bar/templates/base.html.eex",
        "list" => "/foo/bar/templates/list.html.eex",
        "post" => "/foo/bar/templates/post.html.eex"
      }

      assert paths === expected_paths
    end

    test "fails if the returned value is not a list", ctx do
      assert {:error, msg} = get_templates(ctx.super_weird_1)
      assert String.contains?(msg, "Serum.SuperWeirdTheme1.get_templates")
      assert String.contains?(msg, inspect("/foo/bar/baz.html.eex"))
    end

    test "fails if the returned list has non-binary values", ctx do
      assert {:error, msg} = get_templates(ctx.super_weird_2)
      assert String.contains?(msg, "Serum.SuperWeirdTheme2.get_templates")
      assert String.contains?(msg, inspect(42))
    end

    test "may also fail in some other cases", ctx do
      assert {:error, msg} = get_templates(ctx.failing)
      assert String.contains?(msg, "test error from get_templates/0")
    end

    test "does nothing if the theme module is nil", ctx do
      assert {:ok, %{}} === get_templates(ctx.null)
    end
  end

  describe "get_assets/1" do
    test "successfully retrieves a path", ctx do
      tmp_path = get_tmp_dir("serum_test_")
      {:ok, agent} = Agent.start_link(fn -> tmp_path end, name: Serum.TestAgent)

      File.mkdir_p!(tmp_path)
      assert {:ok, tmp_path} === get_assets(ctx.dummy)
      File.rm_rf!(tmp_path)

      :ok = Agent.stop(agent)
    end

    test "returns false to indicate that no asset will be copied", ctx do
      assert {:ok, false} === get_assets(ctx.empty)
    end

    test "fails if the returned path is not a directory", ctx do
      tmp_path = get_tmp_dir("serum_test_")
      {:ok, agent} = Agent.start_link(fn -> tmp_path end, name: Serum.TestAgent)
      expected = {:error, {:enotdir, tmp_path, 0}}

      File.touch!(tmp_path)
      assert expected === get_assets(ctx.weird)
      File.rm_rf!(tmp_path)

      :ok = Agent.stop(agent)
    end

    test "fails if the returned value is not a binary", ctx do
      assert {:error, msg} = get_assets(ctx.super_weird_1)
      assert String.contains?(msg, inspect(42))
    end

    test "may also fail in some other cases", ctx do
      assert {:error, msg} = get_assets(ctx.failing)
      assert String.contains?(msg, "test error from get_assets/0")
    end

    test "does nothing if the theme module is nil", ctx do
      assert {:ok, false} === get_assets(ctx.null)
    end
  end
end
