defmodule Serum.PluginTest do
  use ExUnit.Case
  require Serum.TestHelper
  import ExUnit.CaptureIO
  import Serum.Plugin
  import Serum.Plugin.Client
  import Serum.TestHelper, only: :macros
  alias Serum.File
  alias Serum.Fragment
  alias Serum.IOProxy
  alias Serum.Page
  alias Serum.Post
  alias Serum.PostList
  alias Serum.Template

  "plugins/*plugin*.ex"
  |> fixture()
  |> Path.wildcard()
  |> Enum.each(&Code.require_file/1)

  setup_all do
    {:ok, io_opts} = IOProxy.config()

    IOProxy.config(mute_err: false, mute_msg: false)
    on_exit(fn -> IOProxy.config(Keyword.new(io_opts)) end)
  end

  setup do
    on_exit(fn -> Agent.update(Serum.Plugin, fn _ -> %{} end) end)
  end

  test "callback test" do
    {:ok, _} = load_plugins([Serum.DummyPlugin1, Serum.DummyPlugin2, Serum.DummyPlugin3])

    capture_io(fn ->
      assert {:ok, _} = build_started("/path/to/src", "/path/to/dest")
      assert {:ok, _} = reading_pages(["a", "b", "c"])
      assert {:ok, _} = reading_posts(["a", "b", "c"])
      assert {:ok, _} = reading_templates(["a", "b", "c"])
      assert {:ok, _} = processing_page(%File{src: "page.md"})
      assert {:ok, _} = processing_post(%File{src: "post.md"})
      assert {:ok, _} = processing_template(%File{src: "template.html.eex"})
      assert {:ok, _} = processed_page(%Page{title: "Test Page"})
      assert {:ok, _} = processed_post(%Post{title: "Test Post"})
      assert {:ok, _} = processed_template(%Template{file: "template.html.eex"})
      assert {:ok, _} = processed_list(%PostList{title: "Test Post List"})
      assert {:ok, _} = processed_pages([%Page{title: "Test Page 1"}])
      assert {:ok, _} = processed_posts([%Post{title: "Test Post 1"}])
      assert {:ok, _} = rendering_fragment(%{type: :page}, [{"p", [], ["Hello, world!"]}])
      assert {:ok, _} = rendered_fragment(%Fragment{output: "test.html"})
      assert {:ok, _} = rendered_page(%File{dest: "test.html"})
      assert {:ok, _} = wrote_file(%File{dest: "test.html"})
      assert {:ok, _} = build_succeeded("/src", "/dest")
      assert {:ok, _} = build_failed("/src", "/dest", {:error, "sample error"})
      assert {:ok, _} = finalizing("/src", "/dest")
    end)
  end

  test "failing plugin 1" do
    {:ok, _} = load_plugins([Serum.DummyPlugin1, Serum.FailingPlugin1])

    capture_io(fn ->
      assert {:error, "RuntimeError" <> _} = build_started("", "")
      assert {:error, "RuntimeError" <> _} = reading_posts([])
      assert {:error, "test: processing_page"} == processing_page(%File{})
      assert {:error, "test: finalizing"} == finalizing("", "")

      {:error, msg1} = processing_template(%File{})
      {:error, msg2} = build_succeeded("", "")

      assert String.contains?(msg1, "unexpected")
      assert String.contains?(msg2, "unexpected")
    end)
  end

  describe "show_info/1" do
    test "prints enough information about loaded plugins" do
      {:ok, plugins} = load_plugins([Serum.DummyPlugin1, Serum.DummyPlugin2])
      io_proxy = Process.whereis(IOProxy)
      original_gl = io_proxy |> Process.info() |> Access.get(:group_leader)
      {:ok, string_io} = StringIO.open("")

      Process.group_leader(io_proxy, string_io)
      show_info(plugins)
      Process.group_leader(io_proxy, original_gl)

      {:ok, {_, output}} = StringIO.close(string_io)

      expected = [
        "dummy_plugin_1",
        "0.0.1",
        "Serum.DummyPlugin1",
        "This is dummy plugin no. 1",
        "dummy_plugin_2",
        "Serum.DummyPlugin2",
        "This is dummy plugin no. 2"
      ]

      Enum.each(expected, &assert(String.contains?(output, &1)))
    end

    test "prints nothing when the argument is an empty list" do
      assert "" === capture_io(fn -> show_info([]) end)
    end
  end
end
