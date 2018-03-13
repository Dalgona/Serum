defmodule Serum.Build.Pass3 do
  alias Serum.FileOutput
  alias Serum.Fragment
  alias Serum.Renderer
  alias Serum.Result
  alias Serum.Template

  @spec run(Result.t([Fragment.t()])) :: Result.t()
  def run({:error, _} = error), do: error

  def run({:ok, fragments}) do
    template = Template.get("base")
    result = do_run(fragments, template)

    case Result.aggregate_values(result, :build_pass3) do
      {:ok, outputs} ->
        create_dirs(outputs)
        Enum.each(outputs, &FileOutput.perform_output!/1)

      {:error, _} = error ->
        error
    end
  end

  @spec do_run([Fragment.t()], Template.t()) :: [Result.t(FileOutput.t())]
  defp do_run(fragments, template) do
    fragments
    |> Task.async_stream(&render(&1, template))
    |> Enum.map(&elem(&1, 1))
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
