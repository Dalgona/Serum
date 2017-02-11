defmodule RendererTest do
  use ExUnit.Case, async: true
  import Serum.Build.Renderer

  describe "render/2" do
    test "simple template" do
      template = EEx.compile_string "Hello, world!"
      assert "Hello, world!" == render template, []
      assert "Hello, world!" == render template, [unused: "unused"]
    end

    test "binding" do
      template = EEx.compile_string "Hello, <%= name %>!"
      assert "Hello, world!" == render template, [name: "world"]
    end

    test "undefined function" do
      template = EEx.compile_string "Hello, <%= name() %>!"
      assert_raise CompileError, fn ->
        render template, []
      end
    end
  end

  describe "process_links/2" do
    test "a blank string" do
      assert "" == process_links "", "/test_base/"
    end

    test "no match" do
      assert "hello" == process_links "hello", "/test_base/"
    end

    test "media src from md" do
      expected = ~s(src="/test_base/media/image.jpg")
      code = ~s(src="%25media:image.jpg")
      assert expected == process_links code, "/test_base/"
    end

    test "media href from md" do
      expected = ~s(href="/test_base/media/image.jpg")
      code = ~s(href="%25media:image.jpg")
      assert expected == process_links code, "/test_base/"
    end

    test "media other from md" do
      code = ~s(asdf="%25media:image.jpg")
      assert code == process_links code, "/test_base/"
    end

    test "media src from html" do
      expected = ~s(src="/test_base/media/image.jpg")
      code = ~s(src="%media:image.jpg")
      assert expected == process_links code, "/test_base/"
    end

    test "media href from html" do
      expected = ~s(href="/test_base/media/image.jpg")
      code = ~s(href="%media:image.jpg")
      assert expected == process_links code, "/test_base/"
    end

    test "media other from html" do
      code = ~s(asdf="%media:image.jpg")
      assert code == process_links code, "/test_base/"
    end

    test "post src from md" do
      expected = ~s(src="/test_base/posts/test-post.html")
      code = ~s(src="%25posts:test-post")
      assert expected == process_links code, "/test_base/"
    end

    test "post href from md" do
      expected = ~s(href="/test_base/posts/test-post.html")
      code = ~s(href="%25posts:test-post")
      assert expected == process_links code, "/test_base/"
    end

    test "post other from md" do
      code = ~s(asdf="%25posts:test-post")
      assert code == process_links code, "/test_base/"
    end

    test "post src from html" do
      expected = ~s(src="/test_base/posts/test-post.html")
      code = ~s(src="%posts:test-post")
      assert expected == process_links code, "/test_base/"
    end

    test "post href from html" do
      expected = ~s(href="/test_base/posts/test-post.html")
      code = ~s(href="%posts:test-post")
      assert expected == process_links code, "/test_base/"
    end

    test "post other from html" do
      code = ~s(asdf="%posts:test-post")
      assert code == process_links code, "/test_base/"
    end

    test "page src from md" do
      expected = ~s(src="/test_base/docs/index.html")
      code = ~s(src="%25pages:docs/index")
      assert expected == process_links code, "/test_base/"
    end

    test "page href from md" do
      expected = ~s(href="/test_base/docs/index.html")
      code = ~s(href="%25pages:docs/index")
      assert expected == process_links code, "/test_base/"
    end

    test "page other from md" do
      code = ~s(asdf="%25pages:docs/index")
      assert code == process_links code, "/test_base/"
    end

    test "page src from html" do
      expected = ~s(src="/test_base/docs/index.html")
      code = ~s(src="%pages:docs/index")
      assert expected == process_links code, "/test_base/"
    end

    test "page href from html" do
      expected = ~s(href="/test_base/docs/index.html")
      code = ~s(href="%pages:docs/index")
      assert expected == process_links code, "/test_base/"
    end

    test "page other from html" do
      code = ~s(asdf="%pages:docs/index")
      assert code == process_links code, "/test_base/"
    end

    test "convert multiple occurrences" do
      expected =
        """
        Hello, world! <a href="/test_base/docs/index.html">[Docs]</a>
        <img src="/test_base/media/main/logo.png">
        Latest post: <a href="/test_base/posts/my-post.html">My Post</a>
        """
      code =
        """
        Hello, world! <a href="%25pages:docs/index">[Docs]</a>
        <img src="%media:main/logo.png">
        Latest post: <a href="%25posts:my-post">My Post</a>
        """
      assert expected == process_links code, "/test_base/"
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
