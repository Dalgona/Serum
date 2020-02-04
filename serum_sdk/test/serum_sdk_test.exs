defmodule SerumSdkTest do
  use ExUnit.Case
  doctest SerumSdk

  test "greets the world" do
    assert SerumSdk.hello() == :world
  end
end
