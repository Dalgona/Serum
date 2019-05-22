defmodule Mix.Tasks.Serum.Gen.PageTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Serum.TestHelper
  alias Mix.Tasks.Serum.Gen.Page, as: GenPage

  setup do
    tmp_dir = get_tmp_dir("serum_test_")

    File.mkdir_p!(tmp_dir)
    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    {:ok, tmp_dir: tmp_dir}
  end

  describe "mix serum.gen.page" do
    test "works well with required options only", %{tmp_dir: tmp_dir} do
      File.cd!(tmp_dir, fn ->
        capture_io(fn ->
          GenPage.run(~w(-t Hello -o hello.md))
          GenPage.run(~w(-t Hello -o hello.html.eex))
        end)

        data = File.read!(Path.join([tmp_dir, "pages", "hello.md"]))

        [
          "title: Hello",
          "order: 0"
        ]
        |> Enum.each(&assert String.contains?(data, &1))
      end)
    end

    test "works well with all options", %{tmp_dir: tmp_dir} do
      File.cd!(tmp_dir, fn ->
        capture_io(fn ->
          GenPage.run(~w(-t Hello -o hello.html -l wow -g test -r 3))
        end)

        data = File.read!(Path.join([tmp_dir, "pages", "hello.html"]))

        [
          "title: Hello",
          "group: test",
          "order: 3",
          "label: wow"
        ]
        |> Enum.each(&assert String.contains?(data, &1))
      end)
    end

    test "fails on option type mismatch" do
      assert_raise OptionParser.ParseError, fn ->
        GenPage.run(~w(-t Hello -o hello.html -r foo))
      end
    end

    test "fails if required options are missing" do
      assert_raise OptionParser.ParseError, fn ->
        GenPage.run(~w(-t Hello))
      end
    end

    test "fails if there are extra arguments" do
      assert_raise OptionParser.ParseError, fn ->
        GenPage.run(~w(-t Hello -o hello.html foo bar baz))
      end
    end

    test "fails if there are undefined options" do
      assert_raise OptionParser.ParseError, fn ->
        GenPage.run(~w(-t Hello -o hello.html -x -y --xyzzy))
      end
    end

    test "fails if the file type is invalid" do
      assert_raise Mix.Error, fn ->
        GenPage.run(~w(-t Hello -o hello.txt))
      end
    end
  end
end
