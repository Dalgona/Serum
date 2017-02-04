defmodule ProjectInfoTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Serum.ProjectInfo

  test "load default" do
    info = ProjectInfo.new(%{})
    expected = %Serum.ProjectInfo{
      site_name: "", site_description: "", base_url: "",
      author: "", author_email: "",
      date_format: "{YYYY}-{0M}-{0D}", preview_length: 200,
      list_title_all: "All Posts", list_title_tag: "Posts Tagged ~s"
    }
    assert expected == info
  end

  test "valid date format" do
    info = ProjectInfo.new %{"date_format" => "{WDfull}"}
    assert "{WDfull}" == info.date_format
  end

  test "invalid date format" do
    warn =
      capture_io :stderr, fn ->
        info = ProjectInfo.new %{"date_format" => "{}"}
        send self(), info
      end
    warn_first
      = "\x1b[33m * Invalid date format string `date_format`:\x1b[0m"
    warn_last
      = "\x1b[33m * The default format string will be used instead.\x1b[0m\n"
    assert String.starts_with? warn, warn_first
    assert String.ends_with? warn, warn_last
    assert_received %ProjectInfo{date_format: "{YYYY}-{0M}-{0D}"}
  end

  test "valid list title format" do
    info = ProjectInfo.new %{"list_title_tag" => "Tag: \"~s\""}
    assert "Tag: \"~s\"" == info.list_title_tag
  end

  test "invalid list title format" do
    warn =
      capture_io :stderr, fn ->
        info = ProjectInfo.new %{"list_title_tag" => "666"}
        send self(), info
      end
    warn_first
      = "\x1b[33m * Invalid post list title format string"
    assert String.starts_with? warn, warn_first
    assert_received %ProjectInfo{list_title_tag: "Posts Tagged ~s"}
  end
end
