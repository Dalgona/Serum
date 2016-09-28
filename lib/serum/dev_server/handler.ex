defmodule Serum.DevServer.Handler do
  def init({:tcp, :http}, req, opts) do
    req_path = r req, :path
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
    log 200, "32m", req
    :cowboy_req.reply 200, [{"Content-Type", mime}], contents, req
  end

  defp respond_404(req) do
    log 404, "31m", req
    :cowboy_req.reply 404, [{"Content-Type", "text/plain"}], "Not Found", req
  end

  defp log(code, ansi, req) do
    {{i1, i2, i3, i4}, _} = r req, :peer
    ip_str = Enum.join [i1, i2, i3, i4], "."
    IO.puts "\x1b[#{ansi}[#{code}]\x1b[0m #{ip_str} #{r req, :method} \x1b[1m#{r req, :path}\x1b[0m"
  end

  defp r(req, field) do
    {x, _} = apply :cowboy_req, field, [req]
    x
  end
end
