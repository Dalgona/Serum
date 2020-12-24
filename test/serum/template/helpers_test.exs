defmodule Serum.Template.HelpersTest do
  use Serum.Case
  require Serum.Template.Helpers
  alias Serum.Template
  alias Serum.Template.Helpers
  alias Serum.Template.Storage, as: TS
  alias Serum.V2.Project
  alias Serum.V2.Project.BlogConfiguration

  @assigns [
    project: %Project{
      base_url: URI.parse("https://example.com/base/url"),
      blog: %BlogConfiguration{posts_path: "blog"}
    }
  ]

  setup_all do
    good = EEx.compile_string("Hello, <%= @args[:name] %>!")
    bad = quote(do: raise("test"))

    includes = %{
      "good" => Template.new(good, "good", :include, build(:input_file, src: "good.html.eex")),
      "bad" => Template.new(bad, "bad", :include, build(:input_file, src: "bad.html.eex"))
    }

    TS.load(includes, :include)
    on_exit(fn -> TS.reset() end)
  end

  describe "url/1 (macro)" do
    test "returns an absolute URL of the given path" do
      assigns = @assigns

      assert Helpers.url("hello/world.html") === "/base/url/hello/world.html"
    end
  end

  describe "page_url/1 (macro)" do
    test "returns a URL to the given page" do
      assigns = @assigns

      assert Helpers.page_url("docs/index") === "/base/url/docs/index.html"
    end
  end

  describe "post_url/1 (macro)" do
    test "returns a URL to the given blog post" do
      assigns = @assigns

      assert Helpers.post_url("2019-01-01-test") === "/base/url/blog/2019-01-01-test.html"
    end
  end

  describe "asset_url/1 (macro)" do
    test "returns a URL to the given asset" do
      assigns = @assigns

      assert Helpers.asset_url("css/style.css") === "/base/url/assets/css/style.css"
    end
  end

  describe "render/1" do
    test "dynamically renders an include" do
      assert Helpers.render("good", name: "world") === "Hello, world!"
    end

    test "fails when the given template does not exist" do
      assert_raise RuntimeError, fn -> Helpers.render("foo") end
    end

    test "fails when the extra argument is not a keyword list" do
      assert_raise RuntimeError, fn -> Helpers.render("good", 42) end
    end

    test "fails when the given template raises" do
      assert_raise RuntimeError, fn -> Helpers.render("bad") end
    end
  end

  describe "include/1 (macro)" do
    test "raises an error because this is an invalid call" do
      ast = quote(do: Helpers.include("foo"))

      assert_raise RuntimeError, fn -> Macro.expand(ast, __ENV__) end
    end
  end
end
