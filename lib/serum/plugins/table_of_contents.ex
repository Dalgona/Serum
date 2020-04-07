defmodule Serum.Plugins.TableOfContents do
  @moduledoc """
  A Serum plugin that inserts a table of contents.

  ## Using the Plugin

  First, add this plugin to your `serum.exs`:

      %{
        plugins: [
          #{__MODULE__ |> to_string() |> String.replace_prefix("Elixir.", "")}
        ]
      }

  This plugin works with both pages(`.md`, `.html`, and `.html.eex`) and blog
  posts(`.md`). Insert the `<serum-toc>` tag at the position you want to
  display a table of contents at.

      <serum-toc start="2" end="4"></serum-toc>

  The `start` and `end` attributes define a range of heading level this plugin
  recognizes. In the case of the above example, `<h1>`, `<h5>`, and `<h6>` tags
  are ignored when generating a table of contents.

  After this plugin has run, each `<serum-toc>` tag is replaced with an
  unordered list:

      <ul id="toc" class="serum-toc">
        <li class="indent-0">
          <a href="#s_1">
            <span class="number">1</span>
            Section 1
          </a>
        </li>
        <!-- More list items here... -->
      </ul>

  This plugin produces a "flat" unordered list. However, each list item tag has
  an `indent-x` class, where `x` is an indentation level (from 0 to 5) of the
  current item in the list. You can utilize this when working on stylesheets.

  The `id` attribute of each target heading tag is used when hyperlinks are
  generated. If the element does not have an `id`, the plugin will set one
  appropriately.

  ## Notes

  You may use `<serum-toc>` tag more than once in a single page. However, all
  occurrences of this tag will be replaced with a table of contents generated
  using the attributes of the first one. That is, for example, all three tags
  in the code below expand to the same table of contents, showing a 2-level
  deep list.

      <serum-toc start="2" end="3"></serum-toc>
      ...
      <serum-toc></serum-toc>
      ...
      <serum-toc></serum-toc>

  It's recommended that you wrap a `<serum-toc>` tag with a `<div>` tag when
  using in a markdown file, to ensure a well-formed structure of HTML output.

      <div><serum-toc ...></serum-toc></div>

  And finally, make sure you close every `<serum-toc>` tag properly
  with `</serum-toc>`.
  """

  use Serum.V2.Plugin

  def name, do: "Table of Contents"
  def description, do: "Inserts a table of contents into pages or posts."
  def implements, do: [generating_fragment: 3]

  def generating_fragment(html, metadata, _args)
  def generating_fragment(html, %{type: :page}, _), do: Result.return({insert_toc(html), nil})
  def generating_fragment(html, %{type: :post}, _), do: Result.return({insert_toc(html), nil})
  def generating_fragment(html, _, _), do: Result.return({html, nil})

  @spec insert_toc(Floki.html_tree()) :: Floki.html_tree()
  defp insert_toc(html) do
    case Floki.find(html, "serum-toc") do
      [] ->
        html

      [{"serum-toc", attr_list, _} | _] ->
        {start, end_} = get_range(attr_list)
        state = {start, end_, start, [0], []}
        {new_tree, new_state} = Floki.traverse_and_update(html, state, &tree_fun/2)
        items = new_state |> elem(4) |> Enum.reverse()
        toc = {"ul", [{"id", "toc"}, {"class", "serum-toc"}], items}

        Floki.traverse_and_update(new_tree, fn
          {"serum-toc", _, _} -> toc
          x -> x
        end)
    end
  end

  @spec get_range([{binary(), binary()}]) :: {integer(), integer()}
  defp get_range(attr_list) do
    attr_map = Map.new(attr_list)
    start = attr_map["start"]
    end_ = attr_map["end"]
    start = (start && parse_h_level(start, 1)) || 1
    end_ = (end_ && parse_h_level(end_, 6)) || 6
    end_ = max(start, end_)

    {start, end_}
  end

  @spec parse_h_level(binary(), integer()) :: integer()
  defp parse_h_level(str, default) do
    case Integer.parse(str) do
      {level, ""} -> max(1, min(level, 6))
      _ -> default
    end
  end

  @spec tree_fun(Floki.html_tag(), term()) :: {Floki.html_tag(), term()}
  defp tree_fun(tree, state)

  defp tree_fun({<<?h::8, ch::8, _::binary>>, _, _} = tree, state) when ch in ?1..?6 do
    {start, end_, prev_level, counts, items} = state
    level = ch - ?0

    if level >= start and level <= end_ do
      new_counts = update_counts(counts, level, prev_level)
      num_dot = new_counts |> Enum.reverse() |> Enum.join(".")
      {tree2, id} = try_set_id(tree, "s_#{num_dot}")
      link = toc_link(tree2, num_dot, id)
      item = {"li", [{"class", "indent-#{level - start}"}], [link]}
      new_state = {start, end_, level, new_counts, [item | items]}

      {tree2, new_state}
    else
      {tree, state}
    end
  end

  defp tree_fun(x, state), do: {x, state}

  @spec strip_a_tags(Floki.html_tag()) :: Floki.html_tag()
  defp strip_a_tags(tree)
  defp strip_a_tags({"a", _, children}), do: children
  defp strip_a_tags(x), do: x

  @spec update_counts([integer()], integer(), integer()) :: [integer()]
  defp update_counts(counts, level, prev_level) do
    case level - prev_level do
      0 ->
        [x | xs] = counts

        [x + 1 | xs]

      diff when diff < 0 ->
        [x | xs] = Enum.drop(counts, -diff)

        [x + 1 | xs]

      diff when diff > 0 ->
        List.duplicate(1, diff) ++ counts
    end
  end

  @spec toc_link(Floki.html_tag(), binary(), binary()) :: Floki.html_tag()
  defp toc_link({_, _, children} = _header_tag, num_dot, target_id) do
    num_span = {"span", [{"class", "number"}], [num_dot]}
    contents = Floki.traverse_and_update(children, &strip_a_tags/1)

    {"a", [{"href", <<?#, target_id::binary>>}], [num_span | contents]}
  end

  @spec try_set_id(Floki.html_tag(), binary()) :: {Floki.html_tag(), binary()}
  defp try_set_id({tag_name, attrs, children} = tree, new_id) do
    case Enum.find(attrs, fn {k, _} -> k === "id" end) do
      {"id", id} -> {tree, id}
      nil -> {{tag_name, [{"id", new_id} | attrs], children}, new_id}
    end
  end
end
