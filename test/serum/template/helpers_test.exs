defmodule Serum.Template.HelpersTest do
  use ExUnit.Case
  require Serum.Template.Helpers
  alias Serum.Template
  alias Serum.Template.Helpers
  alias Serum.Template.Storage, as: TS

  @assigns [site: %{base_url: "/base/url"}]

  setup_all do
    good = EEx.compile_string("Hello, <%= @args[:name] %>!")
    bad = quote(do: raise("test"))

    includes = %{
      "good" => Template.new(good, "good", :include, "good"),
      "bad" => Template.new(bad, "bad", :include, "bad")
    }

    TS.load(includes, :include)
    on_exit(fn -> TS.reset() end)
  end

  describe "base/0 (macro)" do
    test "returns the base URL of the project" do
      assigns = @assigns

      assert Helpers.base() === "/base/url"
    end
  end

  describe "base/1 (macro)" do
    test "returns an absolute URL of the given path" do
      assigns = @assigns

      assert Helpers.base("hello/world.html") === "/base/url/hello/world.html"
    end
  end

  describe "page/1 (macro)" do
    test "returns a URL to the given page" do
      assigns = @assigns

      assert Helpers.page("docs/index") === "/base/url/docs/index.html"
    end
  end

  describe "post/1 (macro)" do
    test "returns a URL to the given blog post" do
      assigns = @assigns

      assert Helpers.post("2019-01-01-test") === "/base/url/posts/2019-01-01-test.html"
    end
  end

  describe "asset/1 (macro)" do
    test "returns a URL to the given asset" do
      assigns = @assigns

      assert Helpers.asset("css/style.css") === "/base/url/assets/css/style.css"
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
end
