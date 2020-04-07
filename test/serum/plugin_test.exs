defmodule Serum.PluginTest do
  use ExUnit.Case
  require Serum.TestHelper
  import ExUnit.CaptureIO
  import Serum.Plugin
  import Serum.Plugin.Client
  import Serum.TestHelper, only: :macros
  alias Serum.V2
  alias Serum.V2.Console
  alias Serum.V2.Error
  alias Serum.V2.Fragment
  alias Serum.V2.Page
  alias Serum.V2.Post
  alias Serum.V2.PostList
  alias Serum.V2.Template

  "plugins/*plugin*.ex"
  |> fixture()
  |> Path.wildcard()
  |> Enum.each(&Code.require_file/1)

  setup_all do
    {:ok, io_opts} = Console.config()

    Console.config(mute_err: false, mute_msg: false)
    on_exit(fn -> Console.config(Keyword.new(io_opts)) end)
  end

  setup do
    on_exit(fn -> Agent.update(Serum.Plugin, fn _ -> %{} end) end)
  end

  test "all optional callbacks are correctly called" do
    {:ok, _} = load_plugins([Serum.DummyPlugin])

    capture_io(fn ->
      assert {:ok, _} = build_started(%{})
      assert {:ok, _} = build_succeeded(%{})
      assert {:ok, _} = build_failed(%{}, {:error, %Error{}})
      assert {:ok, _} = reading_pages(["a", "b", "c"])
      assert {:ok, _} = reading_posts(["a", "b", "c"])
      assert {:ok, _} = reading_templates(["a", "b", "c"])
      assert {:ok, _} = processing_pages([%V2.File{src: "page.md"}])
      assert {:ok, _} = processing_posts([%V2.File{src: "post.md"}])
      assert {:ok, _} = processing_templates([%V2.File{src: "template.html.eex"}])
      assert {:ok, _} = processed_pages([%Page{title: "Test Page 1"}])
      assert {:ok, _} = processed_posts([%Post{title: "Test Post 1"}])
      assert {:ok, _} = processed_templates([%Template{source: %V2.File{src: "base.html.eex"}}])
      assert {:ok, _} = generated_post_lists([[%PostList{title: "Test Post List"}]])
      assert {:ok, _} = generating_fragment([{"p", [], ["Hello, world!"]}], %{type: :page})
      assert {:ok, _} = generated_fragment(%Fragment{dest: "test.html"})
      assert {:ok, _} = rendered_pages([%V2.File{dest: "test.html"}])
      assert {:ok, _} = wrote_files([%V2.File{dest: "test.html"}])
    end)

    assert states()[Serum.DummyPlugin] === 1017
  end

  test "failing plugin 1" do
    {:ok, _} = load_plugins([Serum.FailingPlugin1])
    patterns = ~w(RuntimeError build_succeeded 123 RuntimeError reading_posts 456)

    capture_io(fn ->
      [
        build_started(%{}),
        build_succeeded(%{}),
        build_failed(%{}, {:error, %Error{}}),
        reading_pages([]),
        reading_posts([]),
        reading_templates([])
      ]
      |> Enum.map(fn {:error, error} -> to_string(error) end)
      |> Enum.zip(patterns)
      |> Enum.each(fn {message, pattern} -> assert message =~ pattern end)
    end)
  end

  describe "show_info/1" do
    test "prints enough information about loaded plugins" do
      {:ok, plugins} = load_plugins([Serum.DummyPlugin])
      console = Process.whereis(Console)
      original_gl = console |> Process.info() |> Access.get(:group_leader)
      {:ok, string_io} = StringIO.open("")

      Process.group_leader(console, string_io)
      show_info(plugins)
      Process.group_leader(console, original_gl)

      {:ok, {_, output}} = StringIO.close(string_io)

      expected = [
        "dummy_plugin",
        "0.0.1",
        "Serum.DummyPlugin",
        "This is a dummy plugin"
      ]

      Enum.each(expected, &assert(String.contains?(output, &1)))
    end

    test "prints nothing when the argument is an empty list" do
      assert "" === capture_io(fn -> show_info([]) end)
    end
  end
end
