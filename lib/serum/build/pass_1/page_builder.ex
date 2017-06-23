defmodule Serum.Build.Pass1.PageBuilder do
  alias Serum.Error
  alias Serum.Build
  alias Serum.HeaderParser
  alias Serum.PageInfo

  @type state :: Build.state

  @async_opt [max_concurrency: System.schedulers_online * 10]

  @spec run(Build.mode, state) :: Error.result([PageInfo.t])

  def run(mode, state) do
    IO.puts "Collecting pages information..."
    case scan_pages state do
      {:ok, files} ->
        result = launch mode, files, state
        Error.filter_results_with_values result, :page_builder
      {:error, _, _} = error -> error
    end
  end

  @spec launch(Build.mode, [binary], state) :: [Error.result(PageInfo.t)]

  defp launch(:parallel, files, state) do
    files
    |> Task.async_stream(__MODULE__, :page_task, [state], @async_opt)
    |> Enum.map(&(elem &1, 1))
  end

  defp launch(:sequential, files, state) do
    files |> Enum.map(&page_task(&1, state))
  end

  @spec page_task(binary, state) :: Error.result(PageInfo.t)

  def page_task(fname, state) do
    opts = [title: :string, label: :string, group: :string, order: :integer]
    reqs = [:title]
    with {:ok, file} <- File.open(fname, [:read, :utf8]),
         {:ok, header} <- HeaderParser.parse_header(file, fname, opts, reqs)
    do
      File.close file
      {:ok, PageInfo.new(fname, header, state)}
    else
      {:error, reason} -> {:error, :file_error, {reason, fname, 0}}
      {:error, _, _} = error -> error
    end
  end

  @spec scan_pages(state) :: Error.result([binary])

  def scan_pages(state) do
    %{src: src, dest: dest} = state
    dir = src <> "pages/"
    IO.puts "Scanning `#{dir}` directory..."
    if File.exists? dir do
      {:ok, List.flatten(do_scan_pages dir, src, dest)}
    else
      {:error, :file_error, {:enoent, dir, 0}}
    end
  end

  @spec do_scan_pages(binary, binary, binary) :: list(any)

  defp do_scan_pages(path, src, dest) do
    path
    |> File.ls!()
    |> Enum.reduce([], fn x, acc ->
      f = Regex.replace ~r(/+), "#{path}/#{x}", "/"
      cond do
        File.dir? f ->
          f |> String.replace_prefix("#{src}pages/", dest) |> File.mkdir_p!()
          [do_scan_pages(f, src, dest)|acc]
        f =~ ~r/(\.md|\.html|\.html\.eex)$/ ->
          [f|acc]
        :otherwise -> acc
      end
    end)
  end
end
