defmodule Serum.Build.Pass1.PostBuilder do
  import Serum.Util
  alias Serum.Error
  alias Serum.Build
  alias Serum.HeaderParser
  alias Serum.PostInfo

  @type state :: Build.state
  @type erl_datetime :: {erl_date, erl_time}
  @type erl_date :: {non_neg_integer, non_neg_integer, non_neg_integer}
  @type erl_time :: {non_neg_integer, non_neg_integer, non_neg_integer}

  @async_opt [max_concurrency: System.schedulers_online * 10]

  @spec run(Build.mode, state) :: Error.result([PostInfo.t])

  def run(mode, state) do
    IO.puts "Collecting posts information..."
    list = load_file_list "#{state.src}posts/"
    result = launch mode, list, state
    Error.filter_results_with_values result, :post_builder
  end

  @spec load_file_list(binary) :: [binary]

  defp load_file_list(srcdir) do
    case File.ls srcdir do
      {:ok, list} ->
        list
        |> Enum.filter_map(&String.ends_with?(&1, ".md"), fn x ->
          String.replace x, ~r/\.md$/, ""
        end)
        |> Enum.sort
      {:error, _reason} ->
        warn "Cannot access `posts/'. No post will be generated."
        []
    end
  end

  @spec launch(Build.mode, [binary], state) :: [Error.result(PostInfo.t)]

  defp launch(:parallel, files, state) do
    files
    |> Task.async_stream(__MODULE__, :post_task, [state], @async_opt)
    |> Enum.map(&(elem &1, 1))
  end

  defp launch(:sequential, files, state) do
    files |> Enum.map(&post_task(&1, state))
  end

  @spec post_task(binary, state) :: Error.result(PostInfo.t)

  def post_task(file, state) do
    opts = [title: :string, tags: {:list, :string}, date: :datetime]
    reqs = [:title]
    filename = "#{state.src}posts/#{file}.md"
    with {:ok, file} <- File.open(filename, [:read, :utf8]),
         {:ok, header} <- HeaderParser.parse_header(file, filename, opts, reqs)
    do
      html = file |> IO.read(:all) |> Earmark.to_html
      File.close file
      info = PostInfo.new filename, header, html, state
      {:ok, info}
    else
      {:error, reason} -> {:error, :file_error, {reason, filename, 0}}
      {:error, _, _} = error -> error
    end
  end
end
