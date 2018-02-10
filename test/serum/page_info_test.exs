defmodule PageInfoTest do
  use ExUnit.Case
  import Serum.PageInfo

  # Serum.PageInfo <<struct>>
  #  file: path of the source file on disk
  #  title: title of the page
  #  label: label of the page (on nav, etc.)
  #  group: group the page belongs to
  #  order: order which the page appear in its group
  #  url: absolute path of the page on the web

  describe "new/3" do
    # Serum.PageInfo.new(filename, header, state)
  end

  describe "new/3 file type test" do
    test "markdown" do
      info = new(filename(:md), header(:order), state())
      assert info.file == filename(:md)
      assert info.type == ".md"
      assert info.title == "Lorem Ipsum"
      assert info.label == "Test"
      assert info.group == "test"
      assert info.order == 3
      assert info.url == "/test_base/index.html"
      assert info.output == output(:md)
    end

    test "html" do
      info = new(filename(:html), header(:order), state())
      assert info.file == filename(:html)
      assert info.type == ".html"
      assert info.title == "Lorem Ipsum"
      assert info.label == "Test"
      assert info.group == "test"
      assert info.order == 3
      assert info.url == "/test_base/test.html"
      assert info.output == output(:html)
    end

    test "html with eex" do
      info = new(filename(:eex), header(:order), state())
      assert info.file == filename(:eex)
      assert info.type == ".html.eex"
      assert info.title == "Lorem Ipsum"
      assert info.label == "Test"
      assert info.group == "test"
      assert info.order == 3
      assert info.url == "/test_base/hello.html"
      assert info.output == output(:eex)
    end
  end

  describe "new/3 header cases" do
    test "contains only title" do
      info = new(filename(:md), header(:only_title), state())
      assert info.file == filename(:md)
      assert info.type == ".md"
      assert info.title == "Lorem Ipsum"
      assert info.label == "Lorem Ipsum"
      assert info.group == nil
      assert info.order == nil
      assert info.url == "/test_base/index.html"
      assert info.output == output(:md)
    end

    test "contains title and label" do
      info = new(filename(:md), header(:label), state())
      assert info.file == filename(:md)
      assert info.type == ".md"
      assert info.title == "Lorem Ipsum"
      assert info.label == "Test"
      assert info.group == nil
      assert info.order == nil
      assert info.url == "/test_base/index.html"
      assert info.output == output(:md)
    end

    test "contains title, label and group" do
      info = new(filename(:md), header(:group), state())
      assert info.file == filename(:md)
      assert info.type == ".md"
      assert info.title == "Lorem Ipsum"
      assert info.label == "Test"
      assert info.group == "test"
      assert info.order == nil
      assert info.url == "/test_base/index.html"
      assert info.output == output(:md)
    end

    test "contains all metadata" do
      info = new(filename(:md), header(:order), state())
      assert info.file == filename(:md)
      assert info.type == ".md"
      assert info.title == "Lorem Ipsum"
      assert info.label == "Test"
      assert info.group == "test"
      assert info.order == 3
      assert info.url == "/test_base/index.html"
      assert info.output == output(:md)
    end

    test "contains all metadata but label" do
      info = new(filename(:md), header(:no_label), state())
      assert info.file == filename(:md)
      assert info.type == ".md"
      assert info.title == "Lorem Ipsum"
      assert info.label == "Lorem Ipsum"
      assert info.group == "test"
      assert info.order == 3
      assert info.url == "/test_base/index.html"
      assert info.output == output(:md)
    end
  end

  #
  # DATA
  #

  defp filename(:md), do: "/project/test_site/pages/index.md"
  defp filename(:html), do: "/project/test_site/pages/test.html"
  defp filename(:eex), do: "/project/test_site/pages/hello.html.eex"

  defp output(:md), do: "/project/test_site/site/index.html"
  defp output(:html), do: "/project/test_site/site/test.html"
  defp output(:eex), do: "/project/test_site/site/hello.html"

  defp header(:only_title),
    do: %{
      title: "Lorem Ipsum"
    }

  defp header(:label), do: Map.put(header(:only_title), :label, "Test")

  defp header(:group), do: Map.put(header(:label), :group, "test")

  defp header(:order), do: Map.put(header(:group), :order, 3)

  defp header(:no_label), do: Map.delete(header(:order), :label)

  defp state,
    do: %{
      project_info: %{
        base_url: "/test_base/"
      },
      src: "/project/test_site/",
      dest: "/project/test_site/site/"
    }
end
