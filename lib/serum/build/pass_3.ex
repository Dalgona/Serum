defmodule Serum.Build.Pass3 do
  alias Serum.Build
  alias Serum.FileOutput
  alias Serum.Fragment
  alias Serum.Renderer
  alias Serum.Result
  alias Serum.Template

  @spec run(Build.mode(), [Fragment.t()]) :: Result.t()
  def run(build_mode, fragments) do
    template = Template.get("base")
    result = do_run(build_mode, fragments, template)

    case Result.aggregate_values(result, :build_pass3) do
      {:ok, outputs} ->
        create_dirs(outputs)
        Enum.each(outputs, &FileOutput.perform_output!/1)

      {:error, _} = error -> error
    end
  end

  @spec do_run(Build.mode(), [Fragment.t()], Template.t()) ::
    [Result.t(FileOutput.t())]

  defp do_run(build_mode, fragments, template)

  defp do_run(:parallel, fragments, template) do
    fragments
    |> Task.async_stream(&render(&1, template))
    |> Enum.map(&elem(&1, 1))
  end

  defp do_run(:sequential, fragments, template) do
    Enum.map(fragments, &render(&1, template))
  end

  @spec render(Fragment.t(), Template.t()) :: Result.t(FileOutput.t())
  defp render(fragment, template) do
    bindings = [
      page_title: fragment.title,
      page_type: fragment.type,
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

      {:error, _} = error -> error
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
