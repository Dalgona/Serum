defmodule Serum.Plugins.PreviewGenerator do
  @moduledoc """
  A Serum plugin that generates preview texts of pages and blog posts.

  ## Using the Plugin

  First, add this plugin to your `serum.exs`:

      %{
        plugins: [
          # Use this plugin with default options.
          Serum.Plugins.PreviewGenerator

          # Or, use this plugin with custom options.
          {Serum.Plugins.PreviewGenerator, args: options}
        ]
      }

  By default, this plugin takes the text of the first paragraph (`<p>` tag) to
  generate the preview text for each page or blog post. This behavior can be
  customized; see the "Configuration" section below for a list of available
  options.

  Generated preview texts will be saved in `:extras` map of each page or post,
  with `"preview"` key. The name of key can also be customized.

      <%= for post <- @all_posts do %>
        <div class="post-list-item">
          <!-- ... -->
          <p class="preview"><%= post.extras["preview"]</p>
        </div>
      <% end %>

  If a page or a blog post already has `extras["preview"]` (or other key
  specified by the `:preview_key` option), its value will be used instead.

      ---
      title: Sample Blog Post
      date: 2020-07-17
      tags: sample
      preview: This string will be used instead as a preview text of this post.
      ---

      Lorem ipsum dolor sit amet, ...

  ## Configuration

  - `:length`

    A keyword list which determines the maximum length of each preview text.
    Each item of this keyword list is called a "length spec," and a length
    spec should look like one of the followings:

    - `{:chars, max_chars}` - Limits the maximum length of preview texts to
      `max_chars` characters.

    - `{:words, max_words}` - Limits the maximum length of preview texts to
      `max_words` words. Each word is a group of characters splitted by one
      or more whitespace characters.

    - `{:paragraphs, max_paragraphs}` - Limits the maximum length of preview
      texts to `max_paragraphs` paragraphs. This option assumes that contents
      of each page or blog post is well organized using `<p>` tags. Otherwise
      this plugin may produce undesired results.

    This keyword list can have more than one length specs. In that case, this
    plugin will "sample" multiple preview texts for each page or blog post,
    and it will pick the shortest one as a final preview text.

    Defaults to `[paragraphs: 1]`.

  - `:preview_key`

    A string which will be used as an alternative key for storing generated
    preview texts. For example, if you set `:preview_key` to `"summary"`, you
    will be able to access the preview text in your templates like this:

        <% %Serum.Post{} = post %>
        <p><%= post.extras["summary"] %></p>

    Defaults to `"preview"`. If any value is given, any leading or trailing
    whitespaces will be trimmed.

  ### Configuration Example

      # In your serum.exs:
      %{
        plugins: [
          {Serum.Plugins.PreviewGenerator,
           args: [
             length: [paragraphs: 1, chars: 250],
             preview_key: "preview_text"
           ]}
        ]
      }
  """

  @behaviour Serum.Plugin

  alias Serum.Page
  alias Serum.Post
  alias Serum.Result

  @default_options [length: [paragraphs: 1], preview_key: "preview"]

  serum_ver = Version.parse!(Mix.Project.config()[:version])
  serum_req = "~> #{serum_ver.major}.#{serum_ver.minor}"

  @impl true
  @spec name() :: binary()
  def name, do: "Preview Text Generator"

  @impl true
  @spec version() :: binary()
  def version, do: "1.0.0"

  @impl true
  @spec elixir() :: binary()
  def elixir, do: "~> 1.8"

  @impl true
  @spec serum() :: binary()
  def serum, do: unquote(serum_req)

  @impl true
  @spec description() :: binary()
  def description, do: "Generates preview texts of your pages and blog posts."

  @impl true
  @spec implements :: [atom() | {atom(), integer()}]
  def implements do
    [
      build_started: 3,
      processed_pages: 2,
      processed_posts: 2
    ]
  end

  #
  # Optional Callback Implementations
  #

  @impl true
  @spec build_started(binary(), binary(), keyword()) :: Result.t()
  def build_started(_src, _dest, args) do
    [
      (args[:length] && validate_length_specs(args[:length])) || :ok,
      (args[:preview_key] && validate_preview_key(args[:preview_key])) || :ok
    ]
    |> Result.aggregate("failed to validate plugin arguments")
  end

  @impl true
  @spec processed_pages([Page.t()], keyword()) :: Result.t([Page.t()])
  def processed_pages(pages, args) do
    {:ok, put_preview_texts(pages, args)}
  end

  @impl true
  @spec processed_posts([Post.t()], keyword()) :: Result.t([Post.t()])
  def processed_posts(posts, args) do
    {:ok, put_preview_texts(posts, args)}
  end

  #
  # Internal Functions
  #

  @spec validate_length_specs([term()]) :: Result.t()
  defp validate_length_specs(value)

  defp validate_length_specs([_ | _] = length_specs) do
    length_specs
    |> Enum.find(&(!valid_length_spec?(&1)))
    |> case do
      nil ->
        :ok

      invalid_value ->
        {:error, "#{inspect(invalid_value)} is not a valid preview length spec"}
    end
  end

  defp validate_length_specs(anything_else) do
    {:error, "the value of :length must be a list, got: #{anything_else}"}
  end

  @spec valid_length_spec?(term()) :: boolean()
  defp valid_length_spec?(value)
  defp valid_length_spec?({:chars, l}) when is_integer(l) and l >= 0, do: true
  defp valid_length_spec?({:words, l}) when is_integer(l) and l >= 0, do: true
  defp valid_length_spec?({:paragraphs, l}) when is_integer(l) and l >= 0, do: true
  defp valid_length_spec?(_anything_else), do: false

  @spec validate_preview_key(term()) :: Result.t()
  defp validate_preview_key(value)

  defp validate_preview_key(string) when is_binary(string) do
    case String.trim(string) do
      "" ->
        {:error, "the value of :preview_key must not be empty nor contain only whitespaces"}

      _string ->
        :ok
    end
  end

  defp validate_preview_key(_anything_else) do
    {:error, "the value of :preview_key must be a non-empty string"}
  end

  @spec put_preview_texts([content], keyword()) :: [content] when content: Page.t() | Post.t()
  defp put_preview_texts(contents, args) do
    args = Keyword.merge(@default_options, args || [])
    length_specs = reduce_length_specs(args[:length])
    preview_key = String.trim(args[:preview_key])

    Enum.map(contents, &put_preview_text(&1, length_specs, preview_key))
  end

  @spec reduce_length_specs(keyword()) :: keyword()
  defp reduce_length_specs(length_specs) do
    length_specs
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Enum.map(fn {k, v} -> {k, Enum.min(v)} end)
    |> Keyword.new()
  end

  @spec put_preview_text(content, keyword(), binary()) :: content
        when content: Page.t() | Post.t()
  defp put_preview_text(content, length_specs, preview_key) do
    if Map.has_key?(content.extras, preview_key) do
      content
    else
      html = get_html(content)

      preview =
        length_specs
        |> Enum.map(&generate_preview_text(html, &1))
        |> Enum.min_by(&String.length/1, fn -> "" end)

      %{content | extras: Map.put(content.extras, preview_key, preview)}
    end
  end

  @spec get_html(content) :: Floki.html_tree() when content: Page.t() | Post.t()
  defp get_html(content)
  defp get_html(%Page{data: data}), do: Floki.parse_document!(data)
  defp get_html(%Post{html: html}), do: Floki.parse_document!(html)

  @spec generate_preview_text(Floki.html_tree(), {atom(), non_neg_integer()}) :: binary()
  defp generate_preview_text(html, length_spec)
  defp generate_preview_text(_html, {_, l}) when l <= 0, do: ""

  defp generate_preview_text(html, {:chars, l}) do
    html
    |> text_from_html()
    |> String.slice(0, l)
  end

  defp generate_preview_text(html, {:words, l}) do
    html
    |> Floki.text(sep: " ")
    |> String.split(~r/\s/, trim: true)
    |> Enum.take(l)
    |> Enum.join(" ")
  end

  defp generate_preview_text(html, {:paragraphs, l}) do
    html
    |> Floki.find("p")
    |> Enum.take(l)
    |> Enum.map(&text_from_html/1)
    |> Enum.join(" ")
  end

  @spec text_from_html(Floki.html_tree()) :: binary()
  defp text_from_html(html) do
    html
    |> Floki.text(sep: " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end
