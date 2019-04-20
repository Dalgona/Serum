defmodule Serum.PluginTest do
  use ExUnit.Case, async: true
  import Serum.Plugin
  alias Serum.File
  alias Serum.Fragment
  alias Serum.Page
  alias Serum.Post
  alias Serum.PostList
  alias Serum.Template

  :serum
  |> :code.priv_dir()
  |> IO.iodata_to_binary()
  |> Path.join("test_plugins/*plugin*.ex")
  |> Path.wildcard()
  |> Enum.each(&Code.require_file/1)

  test "load_plugins/1" do
    {:ok, loaded_plugins} =
      load_plugins([Serum.DummyPlugin1, Serum.DummyPlugin2, Serum.DummyPlugin3])

    assert length(loaded_plugins) == 3

    agent_state = Agent.get(Serum.Plugin, & &1)

    count =
      Enum.reduce(agent_state, 0, fn {_, plugins}, acc ->
        acc + length(plugins)
      end)

    assert count == 27

    Agent.update(Serum.Plugin, fn _ -> %{} end)
  end

  test "callback test" do
    {:ok, _} = load_plugins([Serum.DummyPlugin1, Serum.DummyPlugin2, Serum.DummyPlugin3])

    assert :ok = build_started("/path/to/src", "/path/to/dest")
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
    assert {:ok, _} = rendered_fragment(%Fragment{output: "test.html"})
    assert {:ok, _} = rendered_page(%File{dest: "test.html"})
    assert :ok = wrote_file(%File{dest: "test.html"})
    assert :ok = build_succeeded("/src", "/dest")
    assert :ok = build_failed("/src", "/dest", {:error, "sample error"})
    assert :ok = finalizing("/src", "/dest")

    Agent.update(Serum.Plugin, fn _ -> %{} end)
  end

  test "env filter" do
    plugins = [
      Serum.DummyPlugin1,
      {Serum.DummyPlugin2, only: :test},
      {Serum.DummyPlugin3, only: [:dev, :prod]}
    ]

    {:ok, loaded} = load_plugins(plugins)
    loaded_mods = Enum.map(loaded, & &1.module)

    assert [Serum.DummyPlugin1, Serum.DummyPlugin2] == loaded_mods
  end

  test "incompatible plugin" do
    output =
      ExUnit.CaptureIO.capture_io(:stderr, fn ->
        {:ok, _} = load_plugins([Serum.IncompatiblePlugin])
      end)

    assert String.contains?(output, "not compatible")
  end

  test "failing plugin 1" do
    {:ok, _} = load_plugins([Serum.DummyPlugin1, Serum.FailingPlugin1])

    assert {:error, "RuntimeError" <> _} = build_started("", "")
    assert {:error, "RuntimeError" <> _} = reading_posts([])
    assert {:error, "test: processing_page"} == processing_page(%File{})
    assert {:error, "test: finalizing"} == finalizing("", "")

    {:error, msg1} = processing_template(%File{})
    {:error, msg2} = build_succeeded("", "")

    assert String.contains?(msg1, "unexpected")
    assert String.contains?(msg2, "unexpected")

    Agent.update(Serum.Plugin, fn _ -> %{} end)
  end

  test "failing plugin 2" do
    assert {:error, {_, [h | _]}} = load_plugins([Serum.FailingPlugin2])
    assert {:error, "RuntimeError" <> _} = h
  end
end
