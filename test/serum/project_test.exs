defmodule Serum.ProjecTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  alias Serum.IOProxy
  alias Serum.Project

  setup_all do
    {:ok, io_opts} = IOProxy.config()

    IOProxy.config(mute_err: false)
    on_exit(fn -> IOProxy.config(Keyword.new(io_opts)) end)
  end

  describe "fallback string format" do
    test "default" do
      proj = Project.new(%{})

      assert proj.date_format === Project.default_date_format()
      assert proj.list_title_tag === Project.default_list_title_tag()
    end

    test "good" do
      date_format = "{WDfull}, {D} {Mshort} {YYYY}"
      list_title_tag = "Posts about ~s"
      map = %{date_format: date_format, list_title_tag: list_title_tag}
      warn = capture_io(:stderr, fn -> send(self(), Project.new(map)) end)

      assert warn === ""

      receive do
        %Project{} = proj ->
          assert proj.date_format === date_format
          assert proj.list_title_tag === list_title_tag
      after
        1000 -> flunk("no message from capture_io after 1 second")
      end
    end

    test "bad date format" do
      date_format = "{WDfull, {D} {Mshort} {YYYY}"
      list_title_tag = "Posts about ~s"
      map = %{date_format: date_format, list_title_tag: list_title_tag}
      warn = capture_io(:stderr, fn -> send(self(), Project.new(map)) end)

      assert String.contains?(warn, "Invalid")

      receive do
        %Project{} = proj ->
          assert proj.date_format === Project.default_date_format()
          assert proj.list_title_tag === list_title_tag
      after
        1000 -> flunk("no message from capture_io after 1 second")
      end
    end

    test "bad list title format" do
      date_format = "{WDfull}, {D} {Mshort} {YYYY}"
      list_title_tag = "Posts about something"
      map = %{date_format: date_format, list_title_tag: list_title_tag}
      warn = capture_io(:stderr, fn -> send(self(), Project.new(map)) end)

      assert String.contains?(warn, "Invalid")

      receive do
        %Project{} = proj ->
          assert proj.date_format === date_format
          assert proj.list_title_tag === Project.default_list_title_tag()
      after
        1000 -> flunk("no message from capture_io after 1 second")
      end
    end

    test "both the date format and the list title format are bad" do
      date_format = "{WDfull, {D} {Mshort} {YYYY}"
      list_title_tag = "Posts about something"
      map = %{date_format: date_format, list_title_tag: list_title_tag}
      warn = capture_io(:stderr, fn -> send(self(), Project.new(map)) end)

      assert String.contains?(warn, "Invalid")

      receive do
        %Project{} = proj ->
          assert proj.date_format === Project.default_date_format()
          assert proj.list_title_tag === Project.default_list_title_tag()
      after
        1000 -> flunk("no message from capture_io after 1 second")
      end
    end
  end

  describe "default values for post paths" do
    test "puts default values when none of them is given" do
      proj = Project.new(%{})

      assert proj.posts_path === "posts"
      assert proj.posts_url === "posts"
      assert proj.tags_url === "tags"
    end

    test "uses posts_path when posts_url is not given" do
      proj = Project.new(%{posts_path: "blog"})

      assert proj.posts_path === "blog"
      assert proj.posts_url === "blog"
      assert proj.tags_url === "tags"
    end

    test "does not fallback if all paths are given" do
      proj =
        Project.new(%{
          posts_path: "posts",
          posts_url: "blog",
          tags_url: "blog/tags"
        })

      assert proj.posts_path === "posts"
      assert proj.posts_url === "blog"
      assert proj.tags_url === "blog/tags"
    end
  end
end
