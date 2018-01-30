defmodule Serum.Page do
  @moduledoc "This module defines Page struct."

  @type t :: %__MODULE__{
    type: binary(),
    title: binary(),
    label: binary(),
    group: binary(),
    order: integer(),
    url: binary(),
    output: binary(),
    data: binary()
  }

  alias Serum.HeaderParser

  defstruct [:type, :title, :label, :group, :order, :url, :output, :data]

  @spec load(binary(), binary(), binary(), map()) :: Error.result(t())
  def load(filename, src, dest, proj) do
    path = Path.join([src, "pages", filename])

    with {:ok, file} <- File.open(path, [:read, :utf8]),
         {:ok, {header, data}} <- get_contents(file, path)
    do
      File.close(file)
      {:ok, create_struct(filename, header, data, dest, proj)}
    else
      {:error, reason} when is_atom(reason) -> {:error, {reason, path, 0}}
      {:error, _} = error -> error
    end
  end

  @spec get_contents(pid(), binary()) :: Error.result(map())
  defp get_contents(file, path) do
    opts = [
      title: :string,
      label: :string,
      group: :string,
      order: :integer
    ]
    required = [:title]

    with {:ok, header} <- HeaderParser.parse_header(file, path, opts, required),
         data when is_binary(data) <- IO.read(file, :all)
    do
      header = %{header | label: header[:label] || header.title}
      {:ok, {header, data}}
    else
      {:error, reason} when is_atom(reason) -> {:error, {reason, path, 0}}
      {:error, _} = error -> error
    end
  end

  @spec create_struct(binary(), map(), binary(), binary(), map()) :: t()
  defp create_struct(filename, header, data, dest, proj) do
    type = get_type filename
    url = Path.join(proj.base_url, filename)
    output = Path.join(dest, Path.rootname(filename, type)) <> ".html"

    __MODULE__
    |> struct(header)
    |> Map.merge(%{
      type: type,
      url: url,
      output: output,
      data: data
    })
  end

  @spec get_type(binary) :: binary

  defp get_type(filename) do
    case Path.extname filename do
      ".eex" ->
        filename
        |> Path.basename(".eex")
        |> Path.extname()
        |> Kernel.<>(".eex")
      ext -> ext
    end
  end
end

defimpl Inspect, for: Serum.Page do
  def inspect(page, _opts), do: ~s(#Serum.Page<"#{page.title}">)
end
