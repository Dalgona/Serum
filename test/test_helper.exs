ExUnit.start()

defmodule Serum.TestHelper do
  @priv_dir :serum |> :code.priv_dir() |> IO.iodata_to_binary()

  defmacro fixture(arg) do
    quote(do: Path.join([unquote(@priv_dir), "fixtures", unquote(arg)]))
  end
end
