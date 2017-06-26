defmodule InitTest do
  use ExUnit.Case
  import Serum.Init
  import Serum.Payload

  @expected_files [
    "/pages", "/pages/index.md", "/posts", "/templates",
    "/templates/base.html.eex", "/templates/list.html.eex",
    "/templates/page.html.eex", "/templates/post.html.eex",
    "/includes", "/includes/nav.html.eex", "/assets/js", "/assets/css",
    "/assets/images", "/media", "/serum.json"
  ]

  setup_all do
    # check if the user has a write permission on /tmp.
    case File.stat "/tmp" do
      {:ok, %File.Stat{access: :read_write}} ->
        :ok
      _ ->
        IO.puts "\x1b[31m/tmp directory must be writable.\x1b[0m"
        :fail
    end
  end

  describe "init/2" do
    # init(dir, force?) => Result
    #   Creates a new Serum project under `dir` directory.
    #
    # BEFORE INIT
    #   * The effective user must have write permission on `dir`.
    #   * `dir` directory must be empty (unless `force?` is true).
    #
    # AFTER INIT
    #   * `dir` directory must contain all expected output.
    #     [proj]/pages
    #     [proj]/pages/index.md
    #     [proj]/posts
    #     [proj]/templates
    #     [proj]/templates/base.html.eex
    #     [proj]/templates/list.html.eex
    #     [proj]/templates/page.html.eex
    #     [proj]/templates/post.html.eex
    #     [proj]/includes
    #     [proj]/includes/nav.html.eex
    #     [proj]/assets/{js,css,images}
    #     [proj]/media
    #     [proj]/serum.json
    #   * Created project must be buildable.

    test "typical usage" do
      dir = "/tmp/serum_test_" <> uniq_name()
      assert :ok == init dir, false
      assert true == all_exists? dir
      assert true == check_templates dir
      File.rm_rf! dir
    end

    test "no write permission" do
      dir = "/tmp/serum_test_" <> uniq_name()
      File.mkdir_p! dir
      :ok = File.chmod dir, 0o000
      result = init dir, false
      assert {:error, :file_error, {:eacces, dir, 0}} == result
      File.chmod dir, 0o755
      File.rm_rf! dir
    end

    test "fail on non-empty dir" do
      dir = "/tmp/serum_test_" <> uniq_name()
      File.mkdir_p! dir
      :ok = File.touch dir <> "/heroes_of_the_storm"
      expected =
        {:error, :init_error,
         {"directory is not empty. use -f (--force) to proceed anyway", dir, 0}}
      result = init dir, false
      assert expected == result
      File.rm_rf! dir
    end

    test "force init" do
      dir = "/tmp/serum_test_" <> uniq_name()
      File.mkdir_p! dir <> "/templates"
      File.touch! dir <> "/templates/base.html.eex"
      assert :ok == init dir, true
      assert true == all_exists? dir
      assert true == check_templates dir
      File.rm_rf! dir
    end
  end

  test "if the new project is buildable" do
    flunk "this test is not implemented"
  end

  @spec uniq_name() :: binary

  defp uniq_name, do: <<System.monotonic_time::size(48)>> |> Base.url_encode64

  @spec all_exists?(binary) :: boolean

  defp all_exists?(dir) do
    result =
      @expected_files
      |> Enum.map(&dir <> &1)
      |> Enum.map(&File.exists?/1)
      |> Enum.uniq
    case result do
      [true] -> true
      _ -> false
    end
  end

  @spec check_templates(binary) :: boolean

  defp check_templates(dir) do
    result_templates =
      [:base, :list, :page, :post]
      |> Enum.map(fn x ->
        template(x) == File.read!(dir <> "/templates/#{x}.html.eex")
      end)
      |> Enum.uniq
    result_includes =
      [:nav]
      |> Enum.map(fn x ->
        include(x) == File.read!(dir <> "/includes/#{x}.html.eex")
      end)
      |> Enum.uniq
    case {result_templates, result_includes} do
      {[true], [true]} -> true
      _ -> false
    end
  end
end