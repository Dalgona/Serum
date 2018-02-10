defmodule InspectTest do
  use ExUnit.Case, async: true

  test "inspect tag" do
    tag = %Serum.Tag{name: "test-tag", list_url: "/test/tags/test-tag/"}
    expected = "#Serum.Tag<\"test-tag\": \"/test/tags/test-tag/\">"
    assert expected == inspect(tag)
  end

  test "inspect postinfo" do
    info = %Serum.PostInfo{
      file: "2017-02-04-1917-test-post",
      title: "Test Post",
      tags: [],
      preview_text: "Hello, world!",
      raw_date: {{2017, 2, 4}, {19, 17, 0}},
      date: "",
      url: ""
    }

    expected = "#Serum.PostInfo<\"Test Post\">"
    assert expected == inspect(info)
  end

  test "inspect pageinfo" do
    info = %Serum.PageInfo{title: "Hello, world!"}
    expected = "#Serum.PageInfo<\"Hello, world!\">"
    assert expected == inspect(info)
  end
end
