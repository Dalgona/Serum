defmodule Serum.UtilTest do
  use ExUnit.Case, async: true
  import Serum.Util
  import ExUnit.CaptureIO

  test "fwrite/2" do
    uniq = <<System.monotonic_time::size(48)>> |> Base.url_encode64
    fname = "/tmp/serum_test_#{uniq}"
    str = "Hello,\nworld!\n"
    fwrite fname, str
    assert str == File.read! fname
    File.rm_rf! fname
  end

  test "warn/1" do
    assert capture_io(:stderr, fn -> warn "test warning" end)
      == "\x1b[33m * test warning\x1b[0m\n"
  end
end
