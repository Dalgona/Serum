defmodule Serum.StructValidator.BlogConfiguration do
  @moduledoc false

  _moduledocp = "A module for validating blog configuration."

  use Serum.StructValidator

  define_validator do
    key :source_dir, rules: [is_binary: []]
    key :posts_path, rules: [is_binary: []]
    key :tags_path, rules: [is_binary: []]
    key :list_title_all, rules: [is_binary: []]
    key :list_title_tag, rules: [is_binary: []]
    key :pagination, rules: [is_boolean: []]
    key :posts_per_page, rules: [is_integer: [], >=: [1]]
    key :list_template, rules: [is_binary: []]
    key :post_template, rules: [is_binary: []]
  end

  def validate(term)
  def validate(false), do: Result.return()
  def validate(term), do: super(term)
end
