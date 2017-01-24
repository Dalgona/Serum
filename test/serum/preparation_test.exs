defmodule Serum.PreparationTest do
  use ExUnit.Case
  import Serum.Build.Preparation

  setup_all do
    on_exit :remove_data, fn -> Serum.init_data end
  end

  describe "load_info/1" do
    test "all ok" do
      assert :ok == load_info priv_dir("testsite_good")
    end

    test "when serum.json is missing" do
      expected = {:error, :file_error, {:enoent, "nonexistent/serum.json", 0}}
      assert expected == load_info "nonexistent/"
    end

    test "malformed json type 1" do
      path = priv_dir "test_projinfo/badjson"
      expected = {:error, :json_error,
        {:invalid_json, path <> "serum.json", 0}
      }
      assert expected == load_info path
    end

    test "malformed json type 2" do
      path = priv_dir "test_projinfo/badjson_info"
      expected = {:error, :json_error,
        {"parse error near `}`", path <> "serum.json", 0}
      }
      assert expected == load_info path
    end

    test "schema validation error" do
      path = priv_dir "test_projinfo/schema_error"
      {:error, reason, {task, suberrors}} = load_info path
      assert reason == :child_tasks
      assert task == :validate_json
      suberrors =
        suberrors
        |> Stream.map(fn {:error, reason, _} -> reason end)
        |> Enum.uniq
      assert suberrors == [:validation_error]
    end
  end

  describe "load_templates/1" do
    test "all ok" do
      assert :ok = load_templates priv_dir("testsite_good")
    end

    # `list.html.eex` and `post.html.eex` are missing.
    test "some are missing" do
      path = priv_dir "test_templates/missing"
      {:error, reason, {task, suberrors}} = load_templates path
      assert reason == :child_tasks
      assert task == :load_templates
      assert 2 == length suberrors
    end

    # `base.html.eex` is malformed
    test "eex syntax error" do
      path = priv_dir "test_templates/eex_error"
      {:error, reason, {task, [suberror]}} = load_templates path
      assert reason == :child_tasks
      assert task == :load_templates
      {:error, reason2, {msg, _, _}} = suberror
      assert reason2 == :invalid_template
      assert msg == "missing token '%>'"
    end

    # `base.html.eex`: SyntaxError
    # `nav.html.eex` : TokenMissingError
    test "elixir syntax error" do
      path = priv_dir "test_templates/elixir_error"
      {:error, reason, {task, [sub1, sub2]}} = load_templates path
      assert reason == :child_tasks
      assert task == :load_templates
      {:error, reason1, {msg1, _, _}} = sub1
      assert reason1 == :invalid_template
      assert msg1 == "syntax error before: '<'"
      {:error, reason2, {msg2, _, _}} = sub2
      assert reason2 == :invalid_template
      assert msg2 == "missing terminator: \" (for string starting at line 1)"
    end
  end

  @spec priv_dir(String.t) :: String.t
  defp priv_dir(dir) do
    priv = :serum |> :code.priv_dir |> IO.iodata_to_binary
    priv <> "/#{dir}/"
  end
end
