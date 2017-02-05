defmodule InitTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  alias Serum.Init
  alias Serum.Payload

  test "init new" do
    uniq = <<System.monotonic_time()::size(48)>> |> Base.url_encode64
    tmpname = "/tmp/serum_#{uniq}/"
    capture_io fn -> send self(), Init.init(tmpname) end
    assert_received :ok
    assert_files tmpname
    File.rm_rf! tmpname
  end

  test "dir already exists" do
    uniq = <<System.monotonic_time()::size(48)>> |> Base.url_encode64
    tmpname = "/tmp/serum_#{uniq}/"
    File.mkdir_p! tmpname
    warn =
      capture_io :stderr, fn ->
        capture_io fn -> send self(), Init.init(tmpname) end
      end
    assert_received :ok
    expected_head = "\x1b[33m * The directory `#{tmpname}` already exists"
    assert String.starts_with? warn, expected_head
    assert_files tmpname
    File.rm_rf! tmpname
  end

  defp assert_files(dir) do
    ["serum.json", "pages/index.md", "posts",
     "templates/base.html.eex", "templates/page.html.eex",
     "templates/list.html.eex", "templates/post.html.eex",
     "templates/nav.html.eex", "assets/css", "assets/js", "assets/images",
     "media", ".gitignore"]
    |> Enum.each(fn f -> assert File.exists? "#{dir}#{f}" end)
    ["base", "page", "list", "post", "nav"]
    |> Enum.each(fn t ->
      file = File.read! "#{dir}templates/#{t}.html.eex"
      assert file == apply Payload, :"template_#{t}", []
    end)
  end
end
