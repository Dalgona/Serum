defmodule Serum.DevServer do
  def run(dir, port) do
    import Supervisor.Spec

    dir = String.ends_with?(dir, "/") && dir || dir <> "/"
    uniq = Base.url_encode64 <<:erlang.monotonic_time::size(64)>>, padding: false
    site = "/tmp/serum_" <> uniq

    if not File.exists? "#{dir}serum.json" do
      IO.puts "[31mError: `#{dir}serum.json` not found."
      IO.puts "Make sure you point at a valid Serum project directory.[0m"
    else
      %{base_url: base} = "#{dir}serum.json"
                          |> File.read!
                          |> Poison.decode!(keys: :atoms)

      Serum.Build.build dir, site, :parallel

      children = [
        worker(__MODULE__, [site, base, port], function: :start_server)
      ]

      opts = [strategy: :one_for_one, name: Serum.DevServer.Supervisor]
      Supervisor.start_link children, opts

      looper
    end
  end

  def start_server(dir, base, port) do
    routes = [
      {"/[...]", Serum.DevServer.Handler, [dir: dir, base: base]}
    ]
    dispatch = :cowboy_router.compile [{:_, routes}]
    opts = [port: port]
    env = [dispatch: dispatch]
    ret = {:ok, _pid} = :cowboy.start_http :http, 100, opts, env: env

    IO.puts "Server started listening on port #{port}."
    IO.puts "Press [1mCtrl-C[0m to quit.\n"
    ret
  end

  defp looper do
    receive do
      _ -> looper
    end
  end
end
