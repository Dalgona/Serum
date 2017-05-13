defmodule Serum.BuildPass1.PageBuilder do
  alias Serum.Error
  alias Serum.Build
  alias Serum.PageInfo

  @type state :: Build.state

  @async_opt [max_concurrency: System.schedulers_online * 10]

  @spec run(Build.mode, state) :: Error.result(state)

  def run(mode, state) do
    build_data = state.build_data
    files = build_data["pages_file"]
    result = launch mode, files, state
    case Error.filter_results_with_values result, :page_builder do
      {:ok, list} ->
        build_data =
          build_data
          |> Map.put("page_info", list)
          |> Map.delete("pages_file")
        {:ok, %{state|build_data: build_data}}
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

  def page_task(fname, _state) do
    case File.open fname do
      {:ok, file} ->
        title = file |> IO.gets("") |> String.trim
        if String.starts_with? title, "# " do
          "# " <> title = title
          {:ok, %PageInfo{file: fname, title: title}}
        else
          {:error, :page_error, {:invalid_header, fname, 0}}
        end
      {:error, reason} ->
        {:error, :file_error, {reason, fname, 0}}
    end
  end
end
