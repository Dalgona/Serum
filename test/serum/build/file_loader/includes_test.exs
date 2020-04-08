defmodule Serum.Build.FileLoader.IncludesTest do
  use Serum.Case
  import Serum.Build.FileLoader.Includes
  alias Serum.Plugin
  alias Serum.Theme

  [
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

    test "loads include files without a theme", %{tmp_dir: tmp_dir} do
      includes_dir = Path.join(tmp_dir, "includes")

      make_files(includes_dir)

      assert {:ok, files} = load(tmp_dir)
      assert 3 === length(files)
    end

    test "loads include files with a theme", %{tmp_dir: tmp_dir} do
      includes_dir = Path.join(tmp_dir, "includes")
      theme_dir = get_tmp_dir("serum_test_")

      make_files(includes_dir)
      File.mkdir_p!(theme_dir)
      File.mkdir_p!(Path.join(theme_dir, "includes"))

      ~w(lorem ipsum)
      |> Enum.map(&(&1 <> ".html.eex"))
      |> Enum.map(&Path.join([theme_dir, "includes", &1]))
      |> Enum.each(&File.touch!/1)

      {:ok, _} = Theme.load(Serum.RealDummyTheme)
      {:ok, agent} = Agent.start_link(fn -> theme_dir end, name: Serum.TestAgent)

      assert {:ok, files} = load(tmp_dir)
      assert 5 === length(files)

      :ok = Agent.stop(agent)

      File.rm_rf!(theme_dir)
    end

    test "succeeds even if the includes directory does not exist", %{tmp_dir: tmp_dir} do
      assert {:ok, []} === load(tmp_dir)
    end

    test "fails when some files cannot be loaded", %{tmp_dir: tmp_dir} do
      includes_dir = Path.join(tmp_dir, "includes")
      foo = Path.join(includes_dir, "foo.html.eex")

      make_files(includes_dir)
      File.chmod!(foo, 0o000)

      assert {:error, _} = load(tmp_dir)

      File.chmod!(foo, 0o644)
    end

    test "fails when a theme fails", %{tmp_dir: tmp_dir} do
      includes_dir = Path.join(tmp_dir, "includes")

      make_files(includes_dir)
      Theme.load(Serum.FailingTheme)

      assert {:error, _} = load(tmp_dir)
    end

    test "fails when a plugin fails", %{tmp_dir: tmp_dir} do
      plugin_mock =
        get_plugin_mock(%{
          {:reading_templates, 2} => fn _, _ -> raise "foo" end
        })

      includes_dir = Path.join(tmp_dir, "includes")
      {:ok, _} = Plugin.load_plugins([plugin_mock])

      make_files(includes_dir)

      assert {:error, _} = load(tmp_dir)
    end
  end

  defp make_files(dir) do
    File.mkdir_p!(dir)

    ~w(foo bar baz)
    |> Enum.map(&(&1 <> ".html.eex"))
    |> Enum.map(&Path.join(dir, &1))
    |> Enum.each(&File.touch!/1)
  end
end
