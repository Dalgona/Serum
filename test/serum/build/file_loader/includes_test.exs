defmodule Serum.Build.FileLoader.IncludesTest do
  use Serum.Case
  alias Serum.Build.FileLoader.Includes, as: IncludeLoader
  alias Serum.Plugin
  alias Serum.Theme
  alias Serum.V2.Error

  describe "load/1 without a theme or plugin" do
    setup :do_common_setup

    test "loads include files", %{dir: dir} do
      assert {:ok, files} = IncludeLoader.load(dir)
      assert length(files) === 3
    end

    test "fails when some files cannot be loaded", ctx do
      foo_include_path = Path.join(ctx.includes_dir, "foo.html.eex")

      File.chmod!(foo_include_path, 0o000)

      assert {:error, %Error{}} = IncludeLoader.load(ctx.dir)

      File.chmod!(foo_include_path, 0o644)
    end

    test "does not fail even if the includes directory does not exist", ctx do
      File.rm_rf!(ctx.includes_dir)

      assert {:ok, []} = IncludeLoader.load(ctx.dir)
    end
  end

  describe "load/1 with a theme" do
    setup :do_common_setup

    setup do
      theme_includes_dir = get_tmp_dir("serum_test_")

      File.mkdir_p!(theme_includes_dir)

      theme_includes =
        ~w(lorem ipsum)
        |> Enum.map(&(&1 <> ".html.eex"))
        |> Enum.map(&Path.join(theme_includes_dir, &1))

      Enum.each(theme_includes, &File.touch!/1)

      on_exit(fn ->
        File.rm_rf!(theme_includes_dir)
        Theme.cleanup()
      end)

      [theme_includes: theme_includes]
    end

    test "loads include files", ctx do
      theme_mock = get_theme_mock(%{get_includes: fn _ -> {:ok, ctx.theme_includes} end})
      {:ok, %Theme{}} = Theme.load(theme_mock)

      assert {:ok, files} = IncludeLoader.load(ctx.dir)
      assert length(files) === 5
    end

    test "returns an error if the loaded theme fails", ctx do
      theme_mock = get_theme_mock(%{get_includes: fn _ -> raise "test: get_includes" end})
      {:ok, %Theme{}} = Theme.load(theme_mock)

      assert {:error, %Error{} = error} = IncludeLoader.load(ctx.dir)

      message = to_string(error)

      assert message =~ "RuntimeError"
      assert message =~ "test: get_includes"
    end
  end

  describe "load/1 with plugins" do
    setup :do_common_setup
    setup do: on_exit(fn -> Plugin.cleanup() end)

    test "returns an error when loaded plugins fail", ctx do
      plugin_mock =
        get_plugin_mock(%{
          {:reading_templates, 2} => fn _, _ -> raise "test: reading_templates/2" end
        })

      {:ok, [%Plugin{}]} = Plugin.load([plugin_mock])

      assert {:error, %Error{} = error} = IncludeLoader.load(ctx.dir)

      message = to_string(error)

      assert message =~ "RuntimeError"
      assert message =~ "test: reading_templates/2"
    end
  end

  defp do_common_setup(_context) do
    tmp_dir = get_tmp_dir("serum_test_")
    includes_dir = Path.join(tmp_dir, "includes")

    File.mkdir_p!(includes_dir)

    ~w(foo bar baz)
    |> Enum.map(&(&1 <> ".html.eex"))
    |> Enum.map(&Path.join(includes_dir, &1))
    |> Enum.each(&File.touch!/1)

    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    [dir: tmp_dir, includes_dir: includes_dir]
  end
end
