defmodule Serum.ProjectValidator do
  all_keys = [
    :site_name,
    :site_description,
    :author,
    :author_email,
    :server_root,
    :base_url,
    :date_format,
    :list_title_all,
    :list_title_tag,
    :pagination,
    :posts_per_page,
    :preview_length
  ]

  required_keys = [
    :site_name,
    :site_description,
    :author,
    :author_email,
    :base_url
  ]

  rules =
    quote do
      [
        site_name: [is_binary: []],
        site_description: [is_binary: []],
        author: [is_binary: []],
        author_email: [is_binary: []],
        server_root: [is_binary: [], =~: [~r[^https?://.+]]],
        base_url: [is_binary: [], =~: [~r[(^/$|^/.*/$)]]],
        date_format: [is_binary: []],
        list_title_all: [is_binary: []],
        list_title_tag: [is_binary: []],
        pagination: [is_boolean: []],
        posts_per_page: [is_integer: [], >=: [1]],
        preview_length: [is_integer: [], >=: [0]]
      ]
    end

  @spec validate_field(atom(), term()) :: :ok | {:fail, binary()}
  defp validate_field(key, value)

  Enum.each(rules, fn {key, exprs} ->
    [x | xs] =
      Enum.map(exprs, fn {func, args} ->
        quote(do: unquote(func)(var!(value), unquote_splicing(args)))
      end)

    check_expr = Enum.reduce(xs, x, &quote(do: unquote(&2) and unquote(&1)))

    [y | ys] =
      Enum.map(exprs, fn {func, args} ->
        quote(do: unquote(func)(value, unquote_splicing(args)))
      end)

    check_str =
      ys
      |> Enum.reduce(y, &quote(do: unquote(&2) and unquote(&1)))
      |> Macro.to_string()

    defp validate_field(unquote(key), value) do
      if unquote(check_expr) do
        :ok
      else
        {:fail, unquote(check_str)}
      end
    end
  end)

  defp validate_field(x, _), do: {:fail, "unknown field \"#{inspect(x)}\""}
end
