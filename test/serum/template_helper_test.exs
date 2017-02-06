defmodule TemplateHelperTest do
  use ExUnit.Case, async: true
  import Serum.TemplateHelper
  alias Serum.SiteBuilder

  defmacro task_with_owner(owner, fun) do
    quote do
      Task.async fn -> Process.link unquote(owner); unquote(fun).() end
    end
  end

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

  describe "base/0, base/1" do
    test "with no arg", %{builder: pid} do
      t = task_with_owner pid, fn -> base() end
      assert "/test_base/" == Task.await t
    end

    test "with arg", %{builder: pid} do
      t = task_with_owner pid, fn -> base "hello/world.html" end
      assert "/test_base/hello/world.html" == Task.await t
    end

    test "leading slash causes duplicate slashes", %{builder: pid} do
      t = task_with_owner pid, fn -> base "/hello/world.html" end
      assert "/test_base//hello/world.html" == Task.await t
    end
  end

  describe "page/1" do
    test "good usage", %{builder: pid} do
      t = task_with_owner pid, fn -> page "index" end
      assert "/test_base/index.html" == Task.await t
    end

    test "good usage 2", %{builder: pid} do
      t = task_with_owner pid, fn -> page "docs/intro" end
      assert "/test_base/docs/intro.html" == Task.await t
    end

    test "trailing .html", %{builder: pid} do
      t = task_with_owner pid, fn -> page "hello.html" end
      assert "/test_base/hello.html.html" == Task.await t
    end

    test "dir", %{builder: pid} do
      t = task_with_owner pid, fn -> page "docs/" end
      assert "/test_base/docs/.html" == Task.await t
    end
  end

  describe "post/1" do
    test "it works", %{builder: pid} do
      t = task_with_owner pid, fn -> post "test" end
      assert "/test_base/posts/test.html" == Task.await t
    end

    test "it really works", %{builder: pid} do
      t = task_with_owner pid, fn -> post "2017-02-05-0948-test-post" end
      assert "/test_base/posts/2017-02-05-0948-test-post.html" == Task.await t
    end

    test "trailing .html", %{builder: pid} do
      t = task_with_owner pid, fn -> post "test.html" end
      assert "/test_base/posts/test.html.html" == Task.await t
    end

    test "leading posts/", %{builder: pid} do
      t = task_with_owner pid, fn -> post "posts/test" end
      assert "/test_base/posts/posts/test.html" == Task.await t
    end
  end

  describe "asset/1" do
    test "it works", %{builder: pid} do
      t = task_with_owner pid, fn -> asset "css/style.css" end
      assert "/test_base/assets/css/style.css" == Task.await t
    end

    test "leading assets/", %{builder: pid} do
      t = task_with_owner pid, fn -> asset "assets/js/script.js" end
      assert "/test_base/assets/assets/js/script.js" == Task.await t
    end
  end

  test "access project metadata", %{builder: pid} do
    t = task_with_owner pid, fn ->
      %{site_name: site_name(),
        site_description: site_description(),
        author: author(),
        author_email: author_email()}
    end
    m = Task.await t
    assert "New Website" == m.site_name
    assert "Welcome to my website!" == m.site_description
    assert "Somebody" == m.author
    assert "somebody@example.com" == m.author_email
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
