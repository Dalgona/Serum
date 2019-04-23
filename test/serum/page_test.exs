defmodule Serum.PageTest do
  use ExUnit.Case, async: true

  alias Serum.Page

  @sample_src "/path/to/src/"
  @sample_dest "/path/to/dest/"
  @sample_base "/mysite/"

  @sample_proj %{
    src: @sample_src,
    dest: @sample_dest,
    base_url: @sample_base
  }

  @sample_header %{
    title: "Hello, world!",
    label: "Home",
    group: "test",
    order: 3
  }

  test "new/4" do
    data = "The quick brown fox jumps over the lazy dog.\n"

    Enum.each([".html", ".html.eex", ".md"], fn type ->
      path = @sample_src <> "/pages/home" <> type
      page = Page.new(path, @sample_header, data, @sample_proj)

      assert page === %Page{
               file: path,
               type: type,
               title: "Hello, world!",
               label: "Home",
               group: "test",
               order: 3,
               url: "/mysite/home.html",
               output: @sample_dest <> "home.html",
               data: data
             }
    end)
  end

  test "compact/1" do
    page = %Page{
      file: "* DELETE ME *",
      type: "* DELETE ME *",
      title: "Hello, world!",
      label: "Home",
      group: "test",
      order: 3,
      url: "/mysite/home.html",
      output: "* DELETE ME *",
      data: "* DELETE ME *"
    }

    compact_page = Page.compact(page)

    refute Map.has_key?(compact_page, :__struct__)
    assert Enum.all?(compact_page, fn {_, v} -> v !== "* DELETE ME *" end)
    assert compact_page.type === :page
  end
end
