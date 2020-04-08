defmodule Serum.Plugin.LoaderTest do
  use Serum.Case
  require Serum.TestHelper
  require Serum.V2.Result, as: Result
  import Serum.Plugin.Loader
  alias Serum.Plugin
  alias Serum.Plugin.State
  alias Serum.V2.Console
  alias Serum.V2.Error

  "plugins/*plugin*.ex"
  |> fixture()
  |> Path.wildcard()
  |> Enum.each(&Code.require_file/1)

  setup_all do
    {:ok, io_opts} = Console.config()

    Console.config(mute_err: false, mute_msg: false)
    on_exit(fn -> Console.config(Keyword.new(io_opts)) end)
  end

  setup do: on_exit(fn -> Agent.update(Plugin, fn _ -> %State{} end) end)

  describe "load_plugins/1" do
    test "always loads plugins without :only option" do
      plugin_specs = [Serum.Plugins.LiveReloader, {Serum.Plugins.TableOfContents, []}]
      {:ok, loaded_plugins} = load_plugins(plugin_specs)

      assert length(loaded_plugins) === 2
    end

    test "loads plugins only with matching Mix environment" do
      plugin_specs = [
        Serum.Plugins.LiveReloader,
        {Serum.Plugins.SitemapGenerator, only: :prod},
        {Serum.Plugins.TableOfContents, only: [:dev, :test]}
      ]

      {:ok, loaded_plugins} = load_plugins(plugin_specs)
      loaded_modules = Enum.map(loaded_plugins, & &1.module)

      assert length(loaded_plugins) === 2
      assert Serum.Plugins.SitemapGenerator not in loaded_modules
    end

    test "returns an error when an invalid plugin spec was given" do
      plugin_specs = [
        123,
        {Serum.Plugins.LiveReloader},
        {Serum.Plugins.SitemapGenerator, [:foo]}
      ]

      assert {:error, %Error{caused_by: errors}} = load_plugins(plugin_specs)
      assert length(errors) === 3
    end

    test "returns an error when the plugin fails to load" do
      Serum.V2.Plugin.Mock
      |> expect(:name, fn -> "" end)
      |> expect(:version, fn -> raise "test: version" end)
      |> expect(:description, fn -> "" end)
      |> expect(:implements, fn -> [] end)

      {:error, error} = load_plugins([Serum.V2.Plugin.Mock])
      message = to_string(error)

      assert message =~ "RuntimeError"
      assert message =~ "test: version"
    end

    test "returns an error when init/0 callback returns an error" do
      Serum.V2.Plugin.Mock
      |> expect(:name, fn -> "" end)
      |> expect(:version, fn -> "0.1.0" end)
      |> expect(:description, fn -> "" end)
      |> expect(:implements, fn -> [] end)
      |> expect(:init, fn _ -> Result.fail(Simple: ["foo"]) end)

      {:error, error} = load_plugins([Serum.V2.Plugin.Mock])
      message = to_string(error)

      assert message =~ "foo"
    end

    test "returns an error when init/0 callback returns something unexpected" do
      Serum.V2.Plugin.Mock
      |> expect(:name, fn -> "" end)
      |> expect(:version, fn -> "0.1.0" end)
      |> expect(:description, fn -> "" end)
      |> expect(:implements, fn -> [] end)
      |> expect(:init, fn _ -> 42 end)

      {:error, error} = load_plugins([Serum.V2.Plugin.Mock])
      message = to_string(error)

      assert message =~ "42"
    end

    test "returns an error when init/0 callback raises an error" do
      Serum.V2.Plugin.Mock
      |> expect(:name, fn -> "" end)
      |> expect(:version, fn -> "0.1.0" end)
      |> expect(:description, fn -> "" end)
      |> expect(:implements, fn -> [] end)
      |> expect(:init, fn _ -> raise "foo" end)

      {:error, error} = load_plugins([Serum.V2.Plugin.Mock])
      message = to_string(error)

      assert message =~ "RuntimeError"
    end
  end
end
