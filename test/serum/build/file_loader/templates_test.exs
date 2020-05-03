defmodule Serum.Build.FileLoader.TemplatesTest do
  use Serum.Case
  alias Serum.Build.FileLoader.Templates, as: TemplateLoader
  alias Serum.Plugin
  alias Serum.Plugin.Loader, as: PluginLoader
  alias Serum.Theme
  alias Serum.Theme.Loader, as: ThemeLoader
  alias Serum.V2.Error

  describe "load/1 without a theme or plugin" do
    setup :do_common_setup

    test "loads template files", %{dir: dir} do
      assert {:ok, files} = TemplateLoader.load(dir)
      assert length(files) === 6
    end

    test "fails when some files cannot be loaded", ctx do
      base_template_path = Path.join(ctx.templates_dir, "base.html.eex")

      File.chmod!(base_template_path, 0o000)

      assert {:error, %Error{}} = TemplateLoader.load(ctx.dir)

      File.chmod!(base_template_path, 0o644)
    end

    test "fails when some of mandatory templates don't exist", ctx do
      ctx.templates_dir |> Path.join("base.html.eex") |> File.rm!()

      assert {:error, %Error{}} = TemplateLoader.load(ctx.dir)
    end
  end

  describe "load/1 with a theme" do
    setup :do_common_setup

    setup do
      theme_templates_dir = get_tmp_dir("serum_test_")

      File.mkdir_p!(theme_templates_dir)

      theme_templates =
        ~w(base page lorem ipsum)
        |> Enum.map(&(&1 <> ".html.eex"))
        |> Enum.map(&Path.join(theme_templates_dir, &1))

      Enum.each(theme_templates, &File.touch!/1)

      on_exit(fn ->
        File.rm_rf!(theme_templates_dir)
        ThemeLoader.load_theme(nil)
      end)

      [theme_templates: theme_templates]
    end

    test "loads template files", ctx do
      ctx.templates_dir |> Path.join("base.html.eex") |> File.rm!()

      theme_mock = get_theme_mock(%{get_templates: fn _ -> {:ok, ctx.theme_templates} end})
      {:ok, %Theme{}} = ThemeLoader.load_theme(theme_mock)

      assert {:ok, files} = TemplateLoader.load(ctx.dir)
      assert length(files) === 8
    end

    test "returns an error if the loaded theme fails", ctx do
      theme_mock = get_theme_mock(%{get_templates: fn _ -> raise "test: get_templates" end})
      {:ok, %Theme{}} = ThemeLoader.load_theme(theme_mock)

      assert {:error, %Error{} = error} = TemplateLoader.load(ctx.dir)

      message = to_string(error)

      assert message =~ "RuntimeError"
      assert message =~ "test: get_templates"
    end
  end

  describe "load/1 with plugins" do
    setup :do_common_setup
    setup do: on_exit(fn -> PluginLoader.load_plugins([]) end)

    test "returns an error when loaded plugins fail", ctx do
      plugin_mock =
        get_plugin_mock(%{
          {:reading_templates, 2} => fn _, _ -> raise "test: reading_templates/2" end
        })

      {:ok, [%Plugin{}]} = PluginLoader.load_plugins([plugin_mock])

      assert {:error, %Error{} = error} = TemplateLoader.load(ctx.dir)

      message = to_string(error)

      assert message =~ "RuntimeError"
      assert message =~ "test: reading_templates/2"
    end
  end

  defp do_common_setup(_context) do
    tmp_dir = get_tmp_dir("serum_test_")
    templates_dir = Path.join(tmp_dir, "templates")

    File.mkdir_p!(templates_dir)

    ~w(base list page post foo bar)
    |> Enum.map(&(&1 <> ".html.eex"))
    |> Enum.map(&Path.join(templates_dir, &1))
    |> Enum.each(&File.touch!/1)

    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    [dir: tmp_dir, templates_dir: templates_dir]
  end
end
