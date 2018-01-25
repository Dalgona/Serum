defmodule Serum.CLI.NewPage do
  @moduledoc false

  use Serum.CLI.Task
  import Serum.Util

  @strict [
    title: :string,
    label: :string,
    group: :string,
    order: :integer,
    output: :string,
  ]
  @aliases [
    t: :title,
    l: :label,
    g: :group,
    r: :order,
    o: :output,
  ]
  @required [:title, :output]
  @in_header [:title, :label, :group, :order]

  def tasks, do: ["newpage"]

  def run(_, args) do
    case OptionParser.parse(args, strict: @strict, aliases: @aliases) do
      {_, _, [{invalid, _} | _]} ->
        # TODO: Needs consistency across all tasks
        warn "Invalid option: #{invalid}"
        {:cli_exit, 2}

      {opts, _, []} ->
        do_run(opts)
    end
  end

  @spec do_run(keyword()) :: {:cli_exit, non_neg_integer}
  defp do_run(opts) do
    with [] <- check_required(opts),
         {:ok, type} <- check_type(opts[:output]),
         output = Path.join("pages/", opts[:output]),
         {:ok, file} <- create_file(output),
         opts <- apply_default(opts)
    do
      io_items = [generate_header(opts), generate_title(opts[:title], type)]
      IO.write(file, io_items)
      File.close(file)
      msg_gen(opts[:output])
      {:cli_exit, 0}
    else
      # From check_required/1:
      [required | _] ->
        warn "`#{required}` option is required, but it is not given."
        {:cli_exit, 2}

      # From check_type/1:
      :invalid ->
        warn "Invalid file name extension."
        warn ~s(Must be one of ".md", ".html", or ".html.eex")
        {:cli_exit, 2}

      # From create_file/1:
      {:error, reason} ->
        reason_str = :file.format_error(reason)
        warn "Could not create a new file: #{reason_str}"
        {:cli_exit, 1}
    end
  end

  @spec check_required(keyword()) :: [atom()]
  defp check_required(opts) do
    Enum.filter(@required, & &1 not in Keyword.keys(opts))
  end

  @spec check_type(binary()) :: {:ok, atom()} | :invalid
  defp check_type(path) do
    cond do
      path =~ ~r/\.md$/ -> {:ok, :md}
      path =~ ~r/\.html$/ -> {:ok, :html}
      path =~ ~r/\.html\.eex$/ -> {:ok, :eex}
      true -> :invalid
    end
  end

  @spec apply_default(keyword()) :: keyword()
  defp apply_default(opts) do
    default = [label: opts[:title], order: 0]
    Keyword.merge(default, opts)
  end

  @spec create_file(binary()) :: {:ok, pid()} | {:error, File.posix()}
  defp create_file(path) do
    dirname = Path.dirname(path)

    unless File.exists?(dirname) do
      File.mkdir_p!(dirname)
      msg_mkdir(dirname)
    end

    File.open(path, [:write, :exclusive, :utf8])
  end

  @spec generate_header(keyword()) :: binary()
  def generate_header(kw) do
    header =
      kw
      |> Enum.filter(fn {k, _v} -> k in @in_header end)
      |> Enum.map(fn {k, v} -> "#{k}: #{v}" end)
      |> Enum.join("\n")
    "---\n" <> header <> "\n---\n\n"
  end

  @spec generate_title(binary(), atom()) :: binary
  defp generate_title(title, type)
  defp generate_title(title, :md), do: "# #{title}\n"
  defp generate_title(title, _), do: "<h1>#{title}</h1>\n"

  def short_help(_task), do: "Add a new page to the current project"

  def synopsis(_task), do: "serum newpage [OPTIONS]"

  def help(_task), do: """
  `serum newpage` helps you add a new page to your project. Some necessary
  directories may be created during the process.

  ## OPTIONS

  * `-t, --title`: Title of the new page. This option is required.
  * `-l, --label`: Label of the new page. Defaults to the page title.
  * `-g, --group`: Optional name of a group the new page belongs to.
  * `-r, --order`: The order of the new page in a group. Defaults to `0`.
  * `-o, --output`: The path where the new page will be saved, relative to
    `pages/` directory. It must end with one of `".md"`, `".html"`,
    or `".html.eex"`. This option is required.
  """
end
