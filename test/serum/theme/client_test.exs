defmodule Serum.Theme.ClientTest do
  use Serum.Case
  require Serum.V2.Result, as: Result
  alias Serum.Theme
  alias Serum.Theme.Client
  alias Serum.Theme.Loader
  alias Serum.V2.Error

  setup(do: on_exit(fn -> Loader.load_theme(nil) end))

  describe "get_includes/0" do
    test "retrieves a list of include file paths from the loaded theme" do
      load_mock(%{get_includes: fn _ -> {:ok, ["foo.html.eex", "bar.html.eex"]} end})

      assert {:ok, includes} = Client.get_includes()
      assert includes === %{"foo" => "foo.html.eex", "bar" => "bar.html.eex"}
    end

    test "filters out invalid list items" do
      load_mock(%{get_includes: fn _ -> {:ok, ["foo.html.eex", "bar"]} end})

      assert {:ok, includes} = Client.get_includes()
      assert includes === %{"foo" => "foo.html.eex"}
    end

    test "returns an error if the returned value is not a list" do
      load_mock(%{get_includes: fn _ -> {:ok, "foo.html.eex"} end})

      assert {:error, %Error{}} = Client.get_includes()
    end

    test "returns an error if the returned list has non-binary items" do
      load_mock(%{get_includes: fn _ -> {:ok, ["foo.html.eex", 42]} end})

      assert {:error, %Error{}} = Client.get_includes()
    end

    test "returns an error if the returned value is not a result" do
      load_mock(%{get_includes: fn _ -> "foo.html.eex" end})

      assert {:error, %Error{}} = Client.get_includes()
    end

    test "passes the returned error through" do
      load_mock(%{get_includes: fn _ -> Result.fail(Simple: ["test: get_includes"]) end})

      assert {:error, %Error{} = error} = Client.get_includes()
      assert to_string(error) =~ "test: get_includes"
    end

    test "returns an error if the theme module raises" do
      load_mock(%{get_includes: fn _ -> raise "test: get_includes" end})

      assert {:error, %Error{} = error} = Client.get_includes()

      message = to_string(error)

      assert message =~ "RuntimeError"
      assert message =~ "test: get_includes"
    end

    test "returns an empty collection if theme is not loaded" do
      Loader.load_theme(nil)

      assert {:ok, %{}} === Client.get_includes()
    end
  end

  describe "get_templates/0" do
    test "retrieves a list of include file paths from the loaded theme" do
      load_mock(%{get_templates: fn _ -> {:ok, ["foo.html.eex", "bar.html.eex"]} end})

      assert {:ok, templates} = Client.get_templates()
      assert templates === %{"foo" => "foo.html.eex", "bar" => "bar.html.eex"}
    end

    test "filters out invalid list items" do
      load_mock(%{get_templates: fn _ -> {:ok, ["foo.html.eex", "bar"]} end})

      assert {:ok, templates} = Client.get_templates()
      assert templates === %{"foo" => "foo.html.eex"}
    end

    test "returns an error if the returned value is not a list" do
      load_mock(%{get_templates: fn _ -> {:ok, "foo.html.eex"} end})

      assert {:error, %Error{}} = Client.get_templates()
    end

    test "returns an error if the returned list has non-binary items" do
      load_mock(%{get_templates: fn _ -> {:ok, ["foo.html.eex", 42]} end})

      assert {:error, %Error{}} = Client.get_templates()
    end

    test "returns an error if the returned value is not a result" do
      load_mock(%{get_templates: fn _ -> "foo.html.eex" end})

      assert {:error, %Error{}} = Client.get_templates()
    end

    test "passes the returned error through" do
      load_mock(%{get_templates: fn _ -> Result.fail(Simple: ["test: get_templates"]) end})

      assert {:error, %Error{} = error} = Client.get_templates()
      assert to_string(error) =~ "test: get_templates"
    end

    test "returns an error if the theme module raises" do
      load_mock(%{get_templates: fn _ -> raise "test: get_templates" end})

      assert {:error, %Error{} = error} = Client.get_templates()

      message = to_string(error)

      assert message =~ "RuntimeError"
      assert message =~ "test: get_templates"
    end

    test "returns an empty collection if theme is not loaded" do
      Loader.load_theme(nil)

      assert {:ok, %{}} === Client.get_templates()
    end
  end

  describe "get_assets/0" do
    setup do
      tmp_dir = get_tmp_dir("serum_test_")

      File.mkdir_p!(tmp_dir)
      tmp_dir |> Path.join("dir") |> File.mkdir_p!()
      tmp_dir |> Path.join("file") |> File.touch!()

      on_exit(fn -> File.rm_rf!(tmp_dir) end)

      {:ok, tmp_dir: tmp_dir}
    end

    test "retrieves a path to assets directory", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "dir")

      load_mock(%{get_assets: fn _ -> {:ok, path} end})

      assert {:ok, ^path} = Client.get_assets()
    end

    test "returns false to indicate that no asset will be copied" do
      load_mock(%{})

      assert {:ok, false} = Client.get_assets()
    end

    test "returns an error if the returned path is not a directory", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "file")

      load_mock(%{get_assets: fn _ -> {:ok, path} end})

      assert {:error, %Error{}} = Client.get_assets()
    end

    test "returns an error if the returned path does not exist", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "non_existent")

      load_mock(%{get_assets: fn _ -> {:ok, path} end})

      assert {:error, %Error{}} = Client.get_assets()
    end

    test "returns an error if the returned value is not a binary" do
      load_mock(%{get_assets: fn _ -> {:ok, 42} end})

      assert {:error, %Error{}} = Client.get_assets()
    end

    test "returns an error if the returned value is not a result" do
      load_mock(%{get_assets: fn _ -> "foo" end})

      assert {:error, %Error{}} = Client.get_assets()
    end

    test "passes the returned error through" do
      load_mock(%{get_assets: fn _ -> Result.fail(Simple: ["test: get_assets"]) end})

      assert {:error, %Error{} = error} = Client.get_assets()
      assert to_string(error) =~ "test: get_assets"
    end

    test "returns an error if the theme module raises" do
      load_mock(%{get_assets: fn _ -> raise "test: get_assets" end})

      assert {:error, %Error{} = error} = Client.get_assets()

      message = to_string(error)

      assert message =~ "RuntimeError"
      assert message =~ "test: get_assets"
    end

    test "returns false if theme is not loaded" do
      Loader.load_theme(nil)

      assert {:ok, false} === Client.get_assets()
    end
  end

  defp load_mock(callbacks) do
    {:ok, %Theme{}} = callbacks |> get_theme_mock() |> Loader.load_theme()
  end
end
