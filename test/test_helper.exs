ExUnit.start()

Serum.V2.Console.config(mute_err: true, mute_msg: true)

defmodule Serum.TestHelper do
  @test_dir Path.join(File.cwd!(), "test_fixtures")

  defmacro fixture(arg) do
    quote(do: Path.join([unquote(@test_dir), unquote(arg)]))
  end

  def get_tmp_dir(prefix) do
    uniq = Base.url_encode64(:crypto.strong_rand_bytes(6))

    Path.expand(prefix <> uniq, System.tmp_dir!())
  end

  def make_project(target) do
    ["" | ~w(pages posts includes templates assets media files)]
    |> Enum.map(&Path.join(target, &1))
    |> Enum.each(&File.mkdir_p!/1)

    File.touch!(Path.join([target, "assets", "test_asset"]))
    File.touch!(Path.join([target, "media", "test_media"]))
    File.touch!(Path.join([target, "files", "test_file.txt"]))
    File.cp!(fixture("proj/good/serum.exs"), Path.join(target, "serum.exs"))
    File.cp!(fixture("templates/nav.html.eex"), Path.join(target, "includes/nav.html.eex"))

    ~w(base list page post)
    |> Enum.map(&["templates/", &1, ".html.eex"])
    |> Enum.each(fn file ->
      File.cp!(fixture(file), Path.join([target, file]))
    end)

    page = "pages/good-*.md" |> fixture() |> Path.wildcard() |> List.first()
    post = "posts/good-*.md" |> fixture() |> Path.wildcard() |> List.first()

    File.cp!(page, Path.join([target, "pages", Path.basename(page)]))
    File.cp!(post, Path.join([target, "posts", Path.basename(post)]))
  end
end

defmodule Serum.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Mox
      import Serum.TestHelper
    end
  end
end
