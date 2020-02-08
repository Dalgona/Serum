defmodule Serum.V2.ConsoleTest do
  use ExUnit.Case
  alias Serum.V2.Console

  test "config/0,1 reads or updates the current configuration" do
    assert {:ok, _} = Console.config(mute_msg: true, mute_err: true)
    assert {:ok, config} = Console.config()

    assert config.mute_msg === true
    assert config.mute_err === true

    assert {:ok, _} = Console.config(mute_msg: false, mute_err: false)
    assert {:ok, config} = Console.config()

    assert config.mute_msg === false
    assert config.mute_err === false
  end
end
