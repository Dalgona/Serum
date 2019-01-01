defmodule Serum.Build.FileEmitter do
  @moduledoc """
  Renders each fragment into a full HTML page and writes to a file.
  """

  alias Serum.Fragment
  alias Serum.Renderer
  alias Serum.Result
  alias Serum.Template

  @spec run([Fragment.t()]) :: Result.t()
  def run(fragments) do
    IO.puts("Writing output files...")

    template = Template.get("base")

    fragments
    |> Task.async_stream(&render(&1, template))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate_values(:build_pass3)
    |> case do
      {:ok, outputs} ->
        create_dirs(outputs)
        Enum.each(outputs, &Serum.File.write/1)

      {:error, _} = error ->
        error
    end
  end

  @spec render(Fragment.t(), Template.t()) :: Result.t(Serum.File.t())
  defp render(fragment, template) do
    bindings = [
      page: fragment.metadata,
      contents: fragment.data
    ]

    case Renderer.render_fragment(template, bindings) do
      {:ok, html} ->
        {:ok,
         %Serum.File{
           src: fragment.file,
           dest: fragment.output,
           in_data: nil,
           out_data: html
         }}

      {:error, _} = error ->
        error
    end
  end

  @spec create_dirs([Serum.File.t()]) :: :ok
  defp create_dirs(outputs) do
    outputs
    |> Stream.map(& &1.dest)
    |> Stream.map(&Path.dirname/1)
    |> Stream.uniq()
    |> Enum.each(fn dir ->
      File.mkdir_p!(dir)
      IO.puts("\x1b[96m MKDIR \x1b[0m#{dir}")
    end)
  end
end
