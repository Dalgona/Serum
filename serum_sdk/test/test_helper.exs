ExUnit.start()

{:ok, _pid} = Serum.V2.Console.start_link([])
{:ok, _} = Serum.V2.Console.config(mute_msg: true, mute_err: true)
