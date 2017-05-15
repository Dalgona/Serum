defmodule Serum.BuildPass1.PostBuilder do
  import Serum.Util
  alias Serum.Error
  alias Serum.Build
  alias Serum.PostInfo

  @type state :: Build.state
  @type erl_datetime :: {erl_date, erl_time}
  @type erl_date :: {non_neg_integer, non_neg_integer, non_neg_integer}
  @type erl_time :: {non_neg_integer, non_neg_integer, non_neg_integer}

  @typep header :: {binary, [Serum.Tag.t], [binary]}

  @re_fname ~r/^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}-[0-9a-z\-]+$/
  @async_opt [max_concurrency: System.schedulers_online * 10]

  @spec run(Build.mode, state) :: Error.result([PostInfo.t])

  def run(mode, state) do
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
    filepath = "#{state.src}posts/#{file}.md"
    base = state.project_info.base_url
    with {:ok, raw_date} <- extract_date(filepath),
         {:ok, header} <- extract_header(filepath, base) do
      info = PostInfo.new filepath, header, raw_date, "", state
      {:ok, info}
    else
      {:error, _, _} = error -> error
    end
  end

  @spec extract_date(binary) :: Error.result(erl_datetime)

  def extract_date(path) do
    fname = :filename.basename path, ".md"
    if fname =~ @re_fname do
      [y, m, d, hhmm|_] =
        fname
        |> String.split("-")
        |> Enum.take(4)
        |> Enum.map(&(&1 |> Integer.parse |> elem(0)))
      {h, i} =
        with h <- div(hhmm, 100), i <- rem(hhmm, 100) do
          h = h > 23 && 23 || h
          i = i > 59 && 59 || i
          {h, i}
        end
      raw_date = {{y, m, d}, {h, i, 0}}
      {:ok, raw_date}
    else
      {:error, :post_error, {:invalid_filename, path, 0}}
    end
  end

  @spec extract_header(binary, binary) :: Error.result(header)

  def extract_header(fname, base) do
    case File.read fname do
      {:ok, data} ->
        do_extract_header fname, data, base
      {:error, reason} ->
        {:error, :file_error, {reason, fname, 0}}
    end
  end

  @spec do_extract_header(binary, binary, binary) :: Error.result(header)

  defp do_extract_header(fname, data, base) do
    try do
      [l1, l2|rest] = data |> String.split("\n")
      {"# " <> title, "#" <> tags} = {l1, l2}
      title = String.trim title
      tags =
        tags
        |> String.split(~r/, */)
        |> Stream.map(&String.trim/1)
        |> Stream.reject(&(&1 == ""))
        |> Enum.sort
        |> Enum.map(&(%Serum.Tag{name: &1, list_url: "#{base}tags/#{&1}"}))
      {:ok, {title, tags, rest}}
    rescue
      _ in MatchError ->
        {:error, :post_error, {:invalid_header, fname, 0}}
    end
  end
end
