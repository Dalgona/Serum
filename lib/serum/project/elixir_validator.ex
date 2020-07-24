defmodule Serum.Project.ElixirValidator do
  @moduledoc false

  _moduledocp = "A module for validation of Serum project definition data."

  use Serum.StructValidator

  define_validator do
    key :site_name, required: true, rules: [is_binary: []]
    key :site_description, required: true, rules: [is_binary: []]
    key :author, required: true, rules: [is_binary: []]
    key :author_email, required: true, rules: [is_binary: []]
    key :server_root, rules: [is_binary: [], =~: [~r[^https?://]]]
    key :base_url, required: true, rules: [is_binary: [], =~: [~r[(^/$|^/.*/$)]]]
    key :date_format, rules: [is_binary: []]
    key :list_title_all, rules: [is_binary: []]
    key :list_title_tag, rules: [is_binary: []]
    key :pagination, rules: [is_boolean: []]
    key :posts_per_page, rules: [is_integer: [], >=: [1]]
    key :preview_length, rules: [valid_preview_length?: []]
    key :plugins, rules: [is_list: []]
    key :theme, rules: [valid_theme_spec?: []]
  end

  @spec valid_preview_length?(term()) :: boolean()
  defp valid_preview_length?(value)
  defp valid_preview_length?(n) when is_integer(n) and n >= 0, do: true
  defp valid_preview_length?({:chars, n}) when is_integer(n) and n >= 0, do: true
  defp valid_preview_length?({:words, n}) when is_integer(n) and n >= 0, do: true
  defp valid_preview_length?({:paragraphs, n}) when is_integer(n) and n >= 0, do: true
  defp valid_preview_length?(_), do: false

  @spec valid_theme_spec?(term()) :: boolean()
  defp valid_theme_spec?(value)
  defp valid_theme_spec?(nil), do: true
  defp valid_theme_spec?(module) when is_atom(module), do: true

  defp valid_theme_spec?({module, opts})
       when not is_nil(module) and is_atom(module) and is_list(opts) do
    true
  end

  defp valid_theme_spec?(_), do: false
end
