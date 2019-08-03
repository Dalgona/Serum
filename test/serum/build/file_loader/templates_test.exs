defmodule Serum.Build.FileLoader.TemplatesTest do
  use ExUnit.Case
  import Serum.Build.FileLoader.Templates
  import Serum.TestHelper
  alias Serum.Plugin
  alias Serum.Theme

  [
    "plugins/failing_plugin_1.ex",
    "theme_modules/real_dummy_theme.ex",
    "theme_modules/failing_theme.ex"
  ]
  |> Enum.map(&fixture/1)
  |> Enum.each(&Code.require_file/1)

  describe "load/1" do
    setup do
      tmp_dir = get_tmp_dir("serum_test_")

      File.mkdir_p!(tmp_dir)

      on_exit(fn ->
        File.rm_rf!(tmp_dir)
        Plugin.load_plugins([])
        Theme.load(nil)
      end)

      {:ok, tmp_dir: tmp_dir}
    end

    test "loads template files without a theme", %{tmp_dir: tmp_dir} do
      templates_dir = Path.join(tmp_dir, "templates")

      make_files(templates_dir)

      assert {:ok, files} = load(tmp_dir)
      assert 4 === length(files)
    end

    test "loads template files with a theme", %{tmp_dir: tmp_dir} do
      templates_dir = Path.join(tmp_dir, "templates")
      theme_dir = get_tmp_dir("serum_test_")

      make_files(templates_dir)
      File.rm!(Path.join(templates_dir, "base.html.eex"))
      File.mkdir_p!(theme_dir)
      File.mkdir_p!(Path.join(theme_dir, "templates"))

      ~w(base lorem ipsum)
      |> Enum.map(&(&1 <> ".html.eex"))
      |> Enum.map(&Path.join([theme_dir, "templates", &1]))
      |> Enum.each(&File.touch!/1)

      {:ok, _} = Theme.load(Serum.RealDummyTheme)
      {:ok, agent} = Agent.start_link(fn -> theme_dir end, name: Serum.TestAgent)

      assert {:ok, files} = load(tmp_dir)
      assert 4 === length(files)

      :ok = Agent.stop(agent)

      File.rm_rf!(theme_dir)
    end

    test "fails when some files cannot be loaded", %{tmp_dir: tmp_dir} do
      templates_dir = Path.join(tmp_dir, "templates")
      base = Path.join(templates_dir, "base.html.eex")

      make_files(templates_dir)
      File.chmod!(base, 0o000)

      assert {:error, _} = load(tmp_dir)

      File.chmod!(base, 0o644)
    end

    test "fails when some of mandatory templates does not exist", %{tmp_dir: tmp_dir} do
      templates_dir = Path.join(tmp_dir, "templates")

      make_files(templates_dir)
      templates_dir |> Path.join("base.html.eex") |> File.rm!()

      assert {:error, _} = load(tmp_dir)
    end

    test "fails when a theme fails", %{tmp_dir: tmp_dir} do
      templates_dir = Path.join(tmp_dir, "templates")

      make_files(templates_dir)
      Theme.load(Serum.FailingTheme)

      assert {:error, _} = load(tmp_dir)
    end

    test "fails when a plugin fails", %{tmp_dir: tmp_dir} do
      templates_dir = Path.join(tmp_dir, "templates")

      make_files(templates_dir)
      Plugin.load_plugins([Serum.FailingPlugin1])

      assert {:error, _} = load(tmp_dir)
    end
  end

  defp make_files(dir) do
    File.mkdir_p!(dir)

    ~w(base list page post foo bar)
    |> Enum.map(&(&1 <> ".html.eex"))
    |> Enum.map(&Path.join(dir, &1))
    |> Enum.each(&File.touch!/1)
  end
end
