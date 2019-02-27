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
  def validate_field(key, value)

  Enum.each(rules, fn {key, exprs} ->
    expr_str =
      exprs
      |> Enum.map(fn {func, args} -> Macro.to_string({func, [], args}) end)
      |> Enum.join(" and ")

    def validate_field(unquote(key), value) do
      result =
        Enum.reduce(unquote(exprs), true, fn {func, args}, acc ->
          acc && apply(Kernel, func, [value | args])
        end)

      if result do
        :ok
      else
        {:fail, unquote(expr_str)}
      end
    end
  end)
end
