defmodule IndexBuilderTest do
  use ExUnit.Case, async: true
  alias Serum.Build.IndexBuilder
  alias Serum.Build.PostBuilder
  alias Serum.Build.Preparation
  alias Serum.PostInfo
  alias Serum.SiteBuilder
  alias Serum.Tag

  describe "run/4" do
    test "posts not built yet" do
      expected = {:error, :file_error, {:enoent, "/xyz/posts/", 0}}
      assert expected == IndexBuilder.run :parallel, %{dest: "/xyz/"}
    end

    test "no posts" do
      null = spawn_link __MODULE__, :looper, []
      src = "#{:code.priv_dir :serum}/testsite_good/"
      uniq = <<System.monotonic_time()::size(48)>> |> Base.url_encode64()
      dest = "/tmp/serum_#{uniq}/"
      {:ok, pid} = SiteBuilder.start_link src, ""
      Process.group_leader self(), null
      Process.group_leader pid, null
      {:ok, proj} = SiteBuilder.load_info pid
      state = %{project_info: proj, build_data: %{}, src: src, dest: dest}
      {:ok, templates} = Preparation.load_templates state
      state = %{state|build_data: Map.put(templates, "all_posts", [])}
      File.mkdir_p! dest <> "posts"
      :ok = IndexBuilder.run :sequential, state
      assert File.exists? dest <> "posts/index.html"
      refute File.exists? dest <> "tags"
      File.rm_rf! dest
      SiteBuilder.stop pid
    end

    test "sequential and parallel" do
      null = spawn_link __MODULE__, :looper, []
      src = "#{:code.priv_dir :serum}/testsite_good/"
      uniq = <<System.monotonic_time()::size(48)>> |> Base.url_encode64()
      dest = "/tmp/serum_#{uniq}/"
      {:ok, pid} = SiteBuilder.start_link src, ""
      Process.group_leader self(), null
      Process.group_leader pid, null
      {:ok, proj} = SiteBuilder.load_info pid
      state = %{project_info: proj, build_data: %{}, src: src, dest: dest}
      {:ok, templates} = Preparation.load_templates state
      state = %{state|build_data: templates}
      {:ok, posts} = PostBuilder.run :sequential, state
      state = %{state|build_data: Map.put(state.build_data, "all_posts", posts)}
      expected_files =
        ["posts/index.html",
         "tags/development/index.html",
         "tags/serum/index.html",
         "tags/test/index.html"]
      :ok = IndexBuilder.run :sequential, state
      Enum.each(expected_files, &assert(File.exists? dest <> &1))
      File.rm_rf! dest
      File.mkdir_p! dest <> "posts"
      :ok = IndexBuilder.run :parallel, state
      Enum.each(expected_files, &assert(File.exists? dest <> &1))
      File.rm_rf! dest
      SiteBuilder.stop pid
    end
  end

  describe "get_tag_map/1" do
    test "no posts" do
      assert %{} == IndexBuilder.get_tag_map []
    end

    test "simple" do
      {tag_a, tag_b, tag_c, tag_d} =
        {%Tag{name: "tag-a"},
         %Tag{name: "tag-b"},
         %Tag{name: "tag-c"},
         %Tag{name: "tag-d"}}
      {post_1, post_2} =
        {%PostInfo{title: "Post 1", tags: [tag_a, tag_b]},
         %PostInfo{title: "Post 2", tags: [tag_c, tag_d]}}
      expected =
        %{tag_a => [post_1], tag_b => [post_1],
          tag_c => [post_2], tag_d => [post_2]}
      assert expected == IndexBuilder.get_tag_map [post_1, post_2]
    end

    test "complex" do
      {tag_a, tag_b, tag_c} =
        {%Tag{name: "tag-a"},
         %Tag{name: "tag-b"},
         %Tag{name: "tag-c"}}
      {post_1, post_2, post_3} =
        {%PostInfo{title: "Post 1", tags: [tag_a, tag_b], file: "xxx"},
         %PostInfo{title: "Post 2", tags: [tag_b, tag_c], file: "yyy"},
         %PostInfo{title: "Post 3", tags: [tag_a, tag_c], file: "zzz"}}
      expected =
        %{tag_a => [post_3, post_1],
          tag_b => [post_2, post_1],
          tag_c => [post_3, post_2]}
      assert expected == IndexBuilder.get_tag_map [post_1, post_2, post_3]
    end
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
