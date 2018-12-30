defmodule Serum.Build.Pass1.PageBuilder do
  alias Serum.Result
  alias Serum.Page

  @spec run(map()) :: Result.t([Page.t()])
  def run(proj) do
    case get_file_list(proj.src) do
      files when is_list(files) ->
        files
        |> Enum.map(&Serum.File.read/1)
        |> Task.async_stream(Page, :load, [proj])
        |> Enum.map(&elem(&1, 1))
        |> Result.aggregate_values(:page_builder)

      {:error, _} = error -> error
    end
  end

  defp get_file_list(src) do
    IO.puts("Collecting pages information...")

    page_dir = (src == "." && "pages") || Path.join(src, "pages")

    if File.exists?(page_dir) do
      [page_dir, "**", "*.{md,html,html.eex}"]
      |> Path.join()
      |> Path.wildcard()
      |> Enum.map(&%Serum.File{src: &1})
    else
      {:error, {:enoent, page_dir, 0}}
    end
  end
end
