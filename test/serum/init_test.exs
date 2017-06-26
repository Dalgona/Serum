defmodule InitTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Serum.Init
  import Serum.Payload
  alias Serum.SiteBuilder

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
      dir = uniq_dir()
      silent_init dir, false
      assert_received :ok
      assert true == all_exists? dir
      assert true == check_templates dir
      File.rm_rf! dir
    end

    test "no write permission" do
      dir = uniq_dir()
      File.mkdir_p! dir
      :ok = File.chmod dir, 0o000
      silent_init dir, false
      assert_received {:error, :file_error, {:eacces, dir, 0}}
      File.chmod dir, 0o755
      File.rm_rf! dir
    end

    test "fail on non-empty dir" do
      dir = uniq_dir()
      File.mkdir_p! dir
      :ok = File.touch dir <> "/heroes_of_the_storm"
      expected =
        {:error, :init_error,
         {"directory is not empty. use -f (--force) to proceed anyway", dir, 0}}
      silent_init dir, false
      assert_received ^expected
      File.rm_rf! dir
    end

    test "force init" do
      dir = uniq_dir()
      File.mkdir_p! dir <> "/templates"
      File.touch! dir <> "/templates/base.html.eex"
      silent_init dir, true
      assert_received :ok
      assert true == all_exists? dir
      assert true == check_templates dir
      File.rm_rf! dir
    end
  end

  @tag skip: "not now!!"

  test "if the new project is buildable" do
    dir = uniq_dir()
    assert :ok == init dir, true
    {:ok, pid} = SiteBuilder.start_link dir, dir <> "site/"
    {:ok, _proj} = SiteBuilder.load_info pid
    assert {:ok, dir <> "site/"} == SiteBuilder.build pid, :parallel
    SiteBuilder.stop pid
    File.rm_rf! dir
  end

  @spec uniq_dir() :: binary

  def uniq_dir do
    uniq = <<System.monotonic_time::size(48)>> |> Base.url_encode64
    "/tmp/serum_test_" <> uniq <> "/"
  end

  @spec silent_init(binary, boolean) :: binary

  defp silent_init(dir, force?) do
    capture_io fn ->
      result = init dir, force?
      send self(), result
    end
  end

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
