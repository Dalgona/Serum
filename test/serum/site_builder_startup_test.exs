defmodule SiteBuilderStartupTest do
  use ExUnit.Case, async: true
  alias Serum.SiteBuilder

  test "starting and stopping" do
    Process.flag :trap_exit, true
    # Start a SiteBuilder process and make sure all subprocesses are alive.
    {:ok, pid} = SiteBuilder.start_link "", ""
    processes =
      [:build_data, :post_info, :project_info]
      |> Enum.map(fn x ->
        list = Registry.lookup Serum.Registry, {x, pid}
        refute list == []
        list |> hd() |> elem(0)
      end)
    for proc <- processes, do: assert Process.alive?(proc)

    # Stop a SiteBuilder process and check if all subprocesses are dead.
    :ok = SiteBuilder.stop pid
    :timer.sleep 1000
    assert_received {:EXIT, pid, :normal}
    refute Process.alive? pid
    for proc <- processes, do: refute Process.alive?(proc)
  end
end
