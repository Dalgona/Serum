defmodule RendererTest do
  use ExUnit.Case, async: true
  alias Serum.Build.Renderer
  alias Serum.SiteBuilder

  setup_all do
    null = spawn_link __MODULE__, :looper, []
    priv = :code.priv_dir :serum
    {:ok, pid} = SiteBuilder.start_link "#{priv}/testsite_good", ""
    Process.group_leader pid, null
    SiteBuilder.load_info pid
    send null, :stop
    on_exit fn -> SiteBuilder.stop pid end
    {:ok, [builder: pid]}
  end

  describe "process_links/2" do
    test "a blank string", %{builder: builder} do
      assert "" == Renderer.process_links "", builder
    end

    test "no match", %{builder: builder} do
      assert "hello" == Renderer.process_links "hello", builder
    end

    test "media src from md", %{builder: builder} do
      expected = ~s(src="/test_base/media/image.jpg")
      code = ~s(src="%25media:image.jpg")
      assert expected == Renderer.process_links code, builder
    end

    test "media href from md", %{builder: builder} do
      expected = ~s(href="/test_base/media/image.jpg")
      code = ~s(href="%25media:image.jpg")
      assert expected == Renderer.process_links code, builder
    end

    test "media other from md", %{builder: builder} do
      code = ~s(asdf="%25media:image.jpg")
      assert code == Renderer.process_links code, builder
    end

    test "media src from html", %{builder: builder} do
      expected = ~s(src="/test_base/media/image.jpg")
      code = ~s(src="%media:image.jpg")
      assert expected == Renderer.process_links code, builder
    end

    test "media href from html", %{builder: builder} do
      expected = ~s(href="/test_base/media/image.jpg")
      code = ~s(href="%media:image.jpg")
      assert expected == Renderer.process_links code, builder
    end

    test "media other from html", %{builder: builder} do
      code = ~s(asdf="%media:image.jpg")
      assert code == Renderer.process_links code, builder
    end

    test "post src from md", %{builder: builder} do
      expected = ~s(src="/test_base/posts/test-post.html")
      code = ~s(src="%25posts:test-post")
      assert expected == Renderer.process_links code, builder
    end

    test "post href from md", %{builder: builder} do
      expected = ~s(href="/test_base/posts/test-post.html")
      code = ~s(href="%25posts:test-post")
      assert expected == Renderer.process_links code, builder
    end

    test "post other from md", %{builder: builder} do
      code = ~s(asdf="%25posts:test-post")
      assert code == Renderer.process_links code, builder
    end

    test "post src from html", %{builder: builder} do
      expected = ~s(src="/test_base/posts/test-post.html")
      code = ~s(src="%posts:test-post")
      assert expected == Renderer.process_links code, builder
    end

    test "post href from html", %{builder: builder} do
      expected = ~s(href="/test_base/posts/test-post.html")
      code = ~s(href="%posts:test-post")
      assert expected == Renderer.process_links code, builder
    end

    test "post other from html", %{builder: builder} do
      code = ~s(asdf="%posts:test-post")
      assert code == Renderer.process_links code, builder
    end

    test "page src from md", %{builder: builder} do
      expected = ~s(src="/test_base/docs/index.html")
      code = ~s(src="%25pages:docs/index")
      assert expected == Renderer.process_links code, builder
    end

    test "page href from md", %{builder: builder} do
      expected = ~s(href="/test_base/docs/index.html")
      code = ~s(href="%25pages:docs/index")
      assert expected == Renderer.process_links code, builder
    end

    test "page other from md", %{builder: builder} do
      code = ~s(asdf="%25pages:docs/index")
      assert code == Renderer.process_links code, builder
    end

    test "page src from html", %{builder: builder} do
      expected = ~s(src="/test_base/docs/index.html")
      code = ~s(src="%pages:docs/index")
      assert expected == Renderer.process_links code, builder
    end

    test "page href from html", %{builder: builder} do
      expected = ~s(href="/test_base/docs/index.html")
      code = ~s(href="%pages:docs/index")
      assert expected == Renderer.process_links code, builder
    end

    test "page other from html", %{builder: builder} do
      code = ~s(asdf="%pages:docs/index")
      assert code == Renderer.process_links code, builder
    end

    test "convert multiple occurrences", %{builder: builder} do
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
      assert expected == Renderer.process_links code, builder
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
