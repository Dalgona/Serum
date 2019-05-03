ExUnit.start()

defmodule Serum.TestHelper do
  @test_dir Path.join(File.cwd!(), "test_fixtures")

  defmacro fixture(arg) do
    quote(do: Path.join([unquote(@test_dir), unquote(arg)]))
  end

  defmacro mute_stdio(do: block) do
    quote do
      ExUnit.CaptureIO.capture_io(fn ->
        send(self(), unquote(block))
      end)

      receive do
        msg -> msg
      after
        1_000 -> "received no message in 1000 milliseconds"
      end
    end
  end
end
