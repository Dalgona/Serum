defmodule Serum.TemplateHelperTest do
  use ExUnit.Case
  import Serum.TemplateHelper
  alias Serum.Build.Preparation
  alias Serum.ProjectInfo

  setup_all do
    priv = :serum |> :code.priv_dir |> IO.iodata_to_binary
    ProjectInfo.start_link
    Preparation.load_info "#{priv}/testsite_good/"
  end

  describe "base/1" do
    test "without argument" do
      assert "/test_base/" == base()
    end

    test "with argument" do
      assert "/test_base/hello/world" == base "hello/world"
    end
  end

  describe "page/1" do
    test "correct usage" do
      assert "/test_base/index.html" == page "index"
    end

    test "GIGO" do
      assert "/test_base/doc/test.html.html" == page "doc/test.html"
    end
  end

  describe "post/1" do
    test "correct usage" do
      assert "/test_base/posts/2017-01-04-0434-test-post.html"
        == post "2017-01-04-0434-test-post"
    end

    test "GIGO type 1" do
      assert "/test_base/posts/2017-01-04-0434-test-post.html.html"
        == post "2017-01-04-0434-test-post.html"
    end

    test "GIGO type 2" do
      assert "/test_base/posts/posts/2017-01-04-0434-test-post.html"
        == post "posts/2017-01-04-0434-test-post"
    end
  end

  describe "asset/1" do
    test "correct usage" do
      assert "/test_base/assets/css/style.css" == asset "css/style.css"
    end

    test "GIGO" do
      assert "/test_base/assets/assets/js/script.js"
        == asset "assets/js/script.js"
    end
  end
end
