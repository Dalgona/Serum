defmodule Serum.PreparationTest do
  use ExUnit.Case, async: true
  import Serum.Build.Preparation

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
      {:error, :child_task, {task, suberrors}} = load_info path
      assert task == :validate_json
      suberrors =
        suberrors
        |> Stream.map(fn {:error, reason, _} -> reason end)
        |> Enum.uniq
      assert suberrors == [:validation_error]
    end
  end

  @spec priv_dir(String.t) :: String.t
  defp priv_dir(dir) do
    priv = :serum |> :code.priv_dir |> IO.iodata_to_binary
    priv <> "/#{dir}/"
  end
end
