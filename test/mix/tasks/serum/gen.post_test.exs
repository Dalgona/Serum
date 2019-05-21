defmodule Mix.Tasks.Serum.Gen.PostTest do
  use ExUnit.Case
  require Serum.TestHelper
  import Serum.TestHelper
  alias Mix.Tasks.Serum.Gen.Post, as: GenPost

  @re_date ~r/[0-9]{4}-[0-9]{2}-[0-9]{2}/

  setup do
    tmp_dir = get_tmp_dir("serum_test_")

    File.mkdir_p!(tmp_dir)
    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    {:ok, tmp_dir: tmp_dir}
  end

  describe "mix serum.gen.post" do
    test "works well with required options only", %{tmp_dir: tmp_dir} do
      File.cd!(tmp_dir, fn ->
        mute_stdio do
          GenPost.run(~w(-t Hello -o hello))
        end

        [path] = tmp_dir |> Path.join("posts/*.md") |> Path.wildcard()
        [date] = path |> (&Regex.run(@re_date, &1)).()
        data = File.read!(path)

        [
          "title: Hello",
          "date: #{date}"
        ]
        |> Enum.each(&assert String.contains?(data, &1))
      end)
    end

    test "works well with all options", %{tmp_dir: tmp_dir} do
      File.cd!(tmp_dir, fn ->
        mute_stdio do
          GenPost.run(~w(-t Hello -o hello.html -g test -g wow))
        end

        [path] = tmp_dir |> Path.join("posts/*.md") |> Path.wildcard()
        [date] = path |> (&Regex.run(@re_date, &1)).()
        data = File.read!(path)

        [
          "title: Hello",
          "date: #{date}",
          "tags: test, wow"
        ]
        |> Enum.each(&assert String.contains?(data, &1))
      end)
    end

    test "fails on option type mismatch" do
      assert_raise OptionParser.ParseError, fn ->
        GenPost.run(~w(-t -o hello))
      end
    end

    test "fails if required options are missing" do
      assert_raise OptionParser.ParseError, fn ->
        GenPost.run(~w(-t Hello))
      end
    end

    test "fails if there are extra arguments" do
      assert_raise OptionParser.ParseError, fn ->
        GenPost.run(~w(-t Hello -o hello foo bar baz))
      end
    end

    test "fails if there are undefined options" do
      assert_raise OptionParser.ParseError, fn ->
        GenPost.run(~w(-t Hello -o hello -x -y --xyzzy))
      end
    end
  end
end
