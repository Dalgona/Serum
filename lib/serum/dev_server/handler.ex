defmodule Serum.DevServer.Handler do
  def init({:tcp, :http}, req, opts) do
    req_path = elem req, 11
    base = String.replace_suffix Keyword.get(opts, :base), "/", ""

    if not String.starts_with? req_path, base do
      {:ok, resp} = respond_404 req
      {:ok, resp, opts}
    else
      path = Keyword.get(opts, :dir) <> String.replace_prefix req_path, base, ""
      {:ok, resp} =
        case File.stat path do
          {:ok, %File.Stat{type: :regular}} -> serve_file path, req
          {:ok, %File.Stat{type: :directory}} -> serve_dir path, req
          {:error, _} -> respond_404 req
        end
      {:ok, resp, opts}
    end
  end

  def handle(req, state), do: {:ok, req, state}

  def terminate(_reason, _req, _state), do: :ok

  defp serve_dir(path, req) do
    path = String.replace_suffix path, "/", ""
    if File.exists? path <> "/index.html" do
      serve_file path <> "/index.html", req
    else
      respond_404 req
    end
  end

  defp serve_file(path, req) do
    ext = Enum.reduce String.split(path, "."), fn x, _ -> x end
    mime = MIME.type ext
    contents = File.read! path
    IO.puts "[32m[200][0m #{elem req, 5} [1m#{elem req, 11}[0m (#{mime})"
    :cowboy_req.reply 200, [{"Content-Type", mime}], contents, req
  end

  defp respond_404(req) do
    IO.puts "[31m[404][0m #{elem req, 5} [1m#{elem req, 11}[0m"
    :cowboy_req.reply 404, [{"Content-Type", "text/plain"}], "Not Found", req
  end
end
