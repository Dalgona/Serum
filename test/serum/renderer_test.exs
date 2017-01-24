defmodule Serum.RendererTest do
  use ExUnit.Case
  import Serum.Build.Renderer

  setup_all do
    Serum.put_data "proj", "base_url", "/test/"
    on_exit :remove_data, fn -> Serum.init_data end
  end

  describe "process_links/1" do
    test "an empty string" do
      assert "" == process_links("")
    end

    test "no match" do
      assert "hello, world!" == process_links("hello, world!")
    end

    test "media (src, from markdown)" do
      expected = ~s(src="/test/media/images/test.jpg")
      str = ~s(src="%25media:images/test.jpg")
      assert expected == process_links(str)
    end

    test "media (href, from markdown)" do
      expected = ~s(href="/test/media/images/test.jpg")
      str = ~s(href="%25media:images/test.jpg")
      assert expected == process_links(str)
    end

    test "media (other, from markdown)" do
      str = ~s(asdf="%25media:images/test.jpg")
      assert str == process_links(str)
    end

    test "pages (src, from markdown)" do
      expected = ~s(src="/test/docs/index.html")
      str = ~s(src="%25pages:docs/index")
      assert expected == process_links(str)
    end

    test "pages (href, from markdown)" do
      expected = ~s(href="/test/docs/index.html")
      str = ~s(href="%25pages:docs/index")
      assert expected == process_links(str)
    end

    test "pages (other, from markdown)" do
      str = ~s(asdf="%25pages:docs/index")
      assert str == process_links(str)
    end

    test "posts (src, from markdown)" do
      expected = ~s(src="/test/posts/2017-01-24-0907-test-post.html")
      str = ~s(src="%25posts:2017-01-24-0907-test-post")
      assert expected == process_links(str)
    end

    test "posts (href, from markdown)" do
      expected = ~s(href="/test/posts/2017-01-24-0907-test-post.html")
      str = ~s(href="%25posts:2017-01-24-0907-test-post")
      assert expected == process_links(str)
    end

    test "posts (other, from markdown)" do
      str = ~s(asdf="%25posts:2017-01-24-0907-test-post")
      assert str == process_links(str)
    end

    test "media (src, html source)" do
      expected = ~s(src="/test/media/images/test.jpg")
      str = ~s(src="%media:images/test.jpg")
      assert expected == process_links(str)
    end

    test "media (href, html source)" do
      expected = ~s(href="/test/media/images/test.jpg")
      str = ~s(href="%media:images/test.jpg")
      assert expected == process_links(str)
    end

    test "media (other, html source)" do
      str = ~s(asdf="%media:images/test.jpg")
      assert str == process_links(str)
    end

    test "pages (src, html source)" do
      expected = ~s(src="/test/docs/index.html")
      str = ~s(src="%pages:docs/index")
      assert expected == process_links(str)
    end

    test "pages (href, html source)" do
      expected = ~s(href="/test/docs/index.html")
      str = ~s(href="%pages:docs/index")
      assert expected == process_links(str)
    end

    test "pages (other, html source)" do
      str = ~s(asdf="%pages:docs/index")
      assert str == process_links(str)
    end

    test "posts (src, html source)" do
      expected = ~s(src="/test/posts/2017-01-24-0907-test-post.html")
      str = ~s(src="%posts:2017-01-24-0907-test-post")
      assert expected == process_links(str)
    end

    test "posts (href, html source)" do
      expected = ~s(href="/test/posts/2017-01-24-0907-test-post.html")
      str = ~s(href="%posts:2017-01-24-0907-test-post")
      assert expected == process_links(str)
    end

    test "posts (other, html source)" do
      str = ~s(asdf="%posts:2017-01-24-0907-test-post")
      assert str == process_links(str)
    end
  end
end
