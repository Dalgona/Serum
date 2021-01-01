defmodule Serum.DevServer.Handler do
  @moduledoc false

  @behaviour :cowboy_handler

  require EEx
  alias Serum.DevServer.Service
  alias Serum.V2.Result

  @typep req :: :cowboy_req.req()

  @service Application.compile_env(:serum, :service, Service.GenServer)

  @impl true
  def init(req, state), do: handle_request(@service.last_build_result(), req, state)

  @spec handle_request(Result.t(binary()), req(), term()) :: {:ok, req(), term()}
  defp handle_request(last_build_result, req, state)

  defp handle_request({:ok, _}, req, state) do
    {:ok, req} = Microscope.default_handler(Serum.Microscope, req)

    {:ok, req, state}
  end

  defp handle_request({:error, error}, req, state) do
    headers = %{"Content-Type" => "text/html"}
    req = :cowboy_req.reply(500, headers, template(error), req)

    {:ok, req, state}
  end

  eex_file =
    :serum
    |> :code.priv_dir()
    |> Path.join("build_resources/error_page.html.eex")

  EEx.function_from_file(:defp, :template, eex_file, [:error])
end
