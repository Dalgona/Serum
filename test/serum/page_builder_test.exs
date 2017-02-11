defmodule PageBuilderTest do
  use ExUnit.Case, async: true
  alias Serum.Build.PageBuilder
  alias Serum.Build.Preparation
  alias Serum.SiteBuilder

  defmacro expect_fail(fname) do
    quote do
      expected = {:error, :page_error, {:invalid_header, unquote(fname), 0}}
      result = PageBuilder.extract_header unquote(fname)
      assert expected == result
    end
  end

  describe "run/4" do
    test "no pages to build" do
      null = spawn_link __MODULE__, :looper, []
      src = "#{:code.priv_dir :serum}/testsite_good/"
      {:ok, pid} = SiteBuilder.start_link src, ""
      Process.group_leader self(), null
      Process.group_leader pid, null

      {:ok, proj} = SiteBuilder.load_info pid
      state = %{project_info: proj, build_data: %{}}
      {:ok, templates} = Preparation.load_templates src, state
      build_data = Map.merge templates, %{"pages_file" => []}
      state = %{state|build_data: build_data}

      uniq = <<System.monotonic_time()::size(48)>> |> Base.url_encode64
      dest = "/tmp/serum_#{uniq}/"
      :ok = PageBuilder.run :sequential, src, dest, state
      File.rm_rf! dest

      SiteBuilder.stop pid
    end

    test "sequential and parallel" do
      null = spawn_link __MODULE__, :looper, []
      src = "#{:code.priv_dir :serum}/testsite_good/"
      {:ok, pid} = SiteBuilder.start_link src, ""
      Process.group_leader self(), null
      Process.group_leader pid, null

      uniq = <<System.monotonic_time()::size(48)>> |> Base.url_encode64
      dest = "/tmp/serum_#{uniq}/"

      {:ok, proj} = SiteBuilder.load_info pid
      state = %{project_info: proj, build_data: %{}}
      {:ok, templates} = Preparation.load_templates src, state
      {:ok, pages} = Preparation.scan_pages src, dest, %{}
      build_data = Map.merge templates, pages
      state = %{state|build_data: build_data}

      :ok = PageBuilder.run :sequential, src, dest, state
      :ok = PageBuilder.run :parallel, src, dest, state
      File.rm_rf! dest
      SiteBuilder.stop pid
    end

    test "returning errors" do
      null = spawn_link __MODULE__, :looper, []
      src = "#{:code.priv_dir :serum}/testsite_bad/"
      {:ok, pid} = SiteBuilder.start_link src, ""
      Process.group_leader self(), null
      Process.group_leader pid, null

      uniq = <<System.monotonic_time()::size(48)>> |> Base.url_encode64
      dest = "/tmp/serum_#{uniq}/"

      {:ok, proj} = SiteBuilder.load_info pid
      state = %{project_info: proj, build_data: %{}}
      {:ok, templates} = Preparation.load_templates src, state
      {:ok, pages} = Preparation.scan_pages src, dest, %{}
      build_data = Map.merge templates, pages
      state = %{state|build_data: build_data}

      expected =
        {:error, :child_tasks,
         {:page_builder,
          [{:error, :page_error,
            {:invalid_header, "#{src}pages/no-header.html", 0}},
           {:error, :page_error,
            {:invalid_header, "#{src}pages/foo/invalid-header.md", 0}}]}}
      assert expected == PageBuilder.run :sequential, src, dest, state

      File.rm_rf! dest
      SiteBuilder.stop pid
    end
  end

  describe "extract_header/1" do
    test "good page" do
      expected = {:ok, {"Example Page", ["", "Hello, world!", ""]}}
      result = PageBuilder.extract_header get_page("good-page.md")
      assert expected == result
    end

    test "no page title" do
      expected = {:ok, {"", ["", "This page does not have a title.", ""]}}
      result = PageBuilder.extract_header get_page("no-title.md")
      assert expected == result
    end

    test "no contents" do
      expected = {:ok, {"An Empty Page", [""]}}
      result = PageBuilder.extract_header get_page("no-content.md")
      assert expected == result
    end

    test "just a pound sign" do
      expect_fail get_page("only-sharp.md")
    end

    test "no space between # and title" do
      expect_fail get_page("no-space.md")
    end

    test "no header" do
      expect_fail get_page("no-header.md")
    end

    test "not even an existing file" do
      expected = {:error, :file_error, {:enoent, "asdf.md", 0}}
      assert expected == PageBuilder.extract_header "asdf.md"
    end
  end

  defp get_page(fname) do
    "#{:code.priv_dir :serum}/test_pages/#{fname}"
  end

  def looper do
    receive do
      {:io_request, from, reply_as, _} when is_pid(from) ->
        send from, {:io_reply, reply_as, :ok}
        looper()
      :stop -> :stop
      _ -> looper()
    end
  end
end
