defmodule PrepTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  import Serum.Build.Preparation

  setup_all do
    {:ok, [state: %{project_info: %{base_url: "/test_base/"}}]}
  end

  describe "load_templates/1" do
    test "all ok", %{state: state} do
      capture_io fn ->
        send self(), load_templates(priv("testsite_good/"), state)
      end
      assert_received(
        {:ok,
         %{"template__base" => _base,
           "template__page" => _page,
           "template__post" => _post,
           "template__list" => _list,
           "template__nav"  => _nav}}
      )
    end

    test "some templates are missing", %{state: state} do
      priv = fn x -> priv("test_templates/missing/templates/" <> x) end
      capture_io fn ->
        send self(), load_templates(priv("test_templates/missing/"), state)
      end
      expected =
        {:error, :child_tasks,
         {:load_templates,
          [{:error, :file_error, {:enoent, priv.("list.html.eex"), 0}},
           {:error, :file_error, {:enoent, priv.("post.html.eex"), 0}}]}}
      assert_received ^expected
    end

    test "some templates contain errors 1", %{state: state} do
      capture_io fn ->
        send self(), load_templates(priv("test_templates/eex_error/"), state)
      end
      receive do
        {:error, :child_tasks, {:load_templates, errors}} ->
          Enum.each errors, fn e ->
            assert elem(e, 0) == :error
            assert elem(e, 1) == :invalid_template
          end
      end
    end

    test "some templates contain errors 2", %{state: state} do
      capture_io fn ->
        send self(), load_templates(priv("test_templates/elixir_error/"), state)
      end
      receive do
        {:error, :child_tasks, {:load_templates, errors}} ->
          Enum.each errors, fn e ->
            assert elem(e, 0) == :error
            assert elem(e, 1) == :invalid_template
          end
      end
    end
  end

  describe "scan_pages/2" do
    test "successfully scanned" do
      expected_files =
        [priv("testsite_good/pages/foo/bar.md"),
         priv("testsite_good/pages/foo/baz.html"),
         priv("testsite_good/pages/index.md"),
         priv("testsite_good/pages/test.html")]
      uniq = <<System.monotonic_time()::size(48)>> |> Base.url_encode64()
      tmpname = "/tmp/serum_#{uniq}/"
      File.mkdir_p! tmpname
      capture_io fn ->
        send self(), scan_pages(priv("testsite_good/"), tmpname, %{})
      end
      receive do
        {:ok, %{"pages_file" => files}} ->
          assert expected_files == Enum.sort(files)
      end
      File.rm_rf! tmpname
    end

    test "source dir does not exist" do
      capture_io fn ->
        send self(), scan_pages("/nonexistent_123/", "", %{})
      end
      expected = {:error, :file_error, {:enoent, "/nonexistent_123/pages/", 0}}
      assert_received ^expected
    end
  end

  defp priv(path) do
    "#{:code.priv_dir :serum}/#{path}"
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
