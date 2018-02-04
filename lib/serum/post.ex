defmodule Serum.Post do
  @moduledoc "This module defines Post struct."

  alias Serum.HeaderParser
  alias Serum.Renderer
  alias Serum.Tag
  alias Serum.Template

  @type t :: %__MODULE__{
    file: binary(),
    title: binary(),
    date: binary(),
    raw_date: {:calendar.date(), :calendar.time()},
    tags: [Tag.t()],
    url: binary(),
    preview_text: binary(),
    html: binary(),
    output: binary()
  }

  defstruct [
    :file, :title, :date, :raw_date, :tags,
    :url, :preview_text, :html, :output
  ]

  @spec load(binary(), map()) :: Error.result(t())
  def load(path, proj) do
    with {:ok, file} <- File.open(path, [:read, :utf8]),
         {:ok, {header, data}} <- get_contents(file, path)
    do
      File.close(file)
      html = Earmark.to_html(data)
      {:ok, create_struct(path, header, html, proj)}
    else
      {:error, reason} when is_atom(reason) -> {:error, {reason, path, 0}}
      {:error, _} = error -> error
    end
  end

  # TODO: Almost the same as Serum.Page.get_contents/2
  @spec get_contents(pid(), binary()) :: Error.result(map())
  defp get_contents(file, path) do
    opts = [
      title: :string,
      tags: {:list, :string},
      date: :datetime
    ]
    required = [:title]

    with {:ok, header} <- HeaderParser.parse_header(file, path, opts, required),
         data when is_binary(data) <- IO.read(file, :all)
    do
      header = %{
        header
        | date: header[:date] || Timex.to_datetime(Timex.zero(), :local)
      }
      {:ok, {header, data}}
    else
      {:error, reason} when is_atom(reason) -> {:error, {reason, path, 0}}
      {:error, _} = error -> error
    end
  end

  @spec create_struct(binary(), map(), binary(), map()) :: t()
  defp create_struct(path, header, html, proj) do
    tags = Tag.batch_create(header[:tags], proj)
    datetime = header[:date]
    date_str = Timex.format! datetime, proj.date_format
    raw_date = datetime |> Timex.to_erl
    filename =
      path
      |> String.replace_suffix("md", "html")
      |> Path.relative_to(proj.src)

    %__MODULE__{
      file: path,
      title: header.title,
      tags: tags,
      html: html,
      preview_text: make_preview(html, proj.preview_length),
      raw_date: raw_date,
      date: date_str,
      url: Path.join(proj.base_url, filename),
      output: Path.join(proj.dest, filename)
    }
  end

  @spec make_preview(binary, non_neg_integer) :: binary

  defp make_preview(html, maxlen) do
    case maxlen do
      0 -> ""
      x when is_integer(x) ->
        parsed =
          case Floki.parse html do
            t when is_tuple(t) -> [t]
            l when is_list(l)  -> l
          end
        parsed
        |> Enum.filter(&elem(&1, 0) == "p")
        |> Enum.map(&Floki.text/1)
        |> Enum.join(" ")
        |> String.slice(0, x)
    end
  end

  @spec to_html(t(), map()) :: Error.result(binary())
  def to_html(%__MODULE__{} = post, proj) do
    bindings = [
      title: post.title, date: post.date, raw_date: post.raw_date,
      tags: post.tags, contents: post.html
    ]
    template = Template.get("post")

    case Renderer.render_stub(template, bindings) do
      {:ok, rendered} ->
        {:ok, Renderer.process_links(rendered, proj.base_url)}
      {:error, _} = error -> error
    end
  end
end

defimpl Inspect, for: Serum.Post do
  def inspect(post, _opts), do: ~s(#Serum.Post<"#{post.title}">)
end
