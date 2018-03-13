defmodule Serum.Build.Pass3 do
  alias Serum.Build
  alias Serum.FileOutput
  alias Serum.Fragment
  alias Serum.Renderer
  alias Serum.Result
  alias Serum.Template

  @spec run(Result.t([Fragment.t()]), Build.mode()) :: Result.t()
  def run({:error, _} = error, _build_mode), do: error

  def run({:ok, fragments}, build_mode) do
    template = Template.get("base")
    result = do_run(fragments, template, build_mode)

    case Result.aggregate_values(result, :build_pass3) do
      {:ok, outputs} ->
        create_dirs(outputs)
        Enum.each(outputs, &FileOutput.perform_output!/1)

      {:error, _} = error ->
        error
    end
  end

  @spec do_run([Fragment.t()], Template.t(), Build.mode()) :: [Result.t(FileOutput.t())]

  defp do_run(fragments, template, build_mode)

  defp do_run(fragments, template, :parallel) do
    fragments
    |> Task.async_stream(&render(&1, template))
    |> Enum.map(&elem(&1, 1))
  end

  defp do_run(fragments, template, :sequential) do
    Enum.map(fragments, &render(&1, template))
  end

  @spec render(Fragment.t(), Template.t()) :: Result.t(FileOutput.t())
  defp render(fragment, template) do
    bindings = [
      page: fragment.metadata,
      contents: fragment.data
    ]

    case Renderer.render_fragment(template, bindings) do
      {:ok, html} ->
        {:ok,
         %FileOutput{
           src: fragment.file,
           dest: fragment.output,
           data: html
         }}

      {:error, _} = error ->
        error
    end
  end

  @spec create_dirs([FileOutput.t()]) :: :ok
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
