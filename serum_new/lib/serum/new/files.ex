defmodule Serum.New.Files do
  @moduledoc false

  require Mix.Generator

  priv_dir = :code.priv_dir(:serum_new)
  get_priv = fn path -> File.read!("#{priv_dir}/#{path}") end

  # Templates
  [
    {:gitignore, get_priv.("gitignore.eex")},
    {:mix_exs, get_priv.("mix.exs.eex")},
    {:serum_exs, get_priv.("serum.exs.eex")},
    {:theme_module, get_priv.("theme_module.ex.eex")}
  ]
  |> Enum.each(fn {name, contents} ->
    def template(unquote(name), assigns) do
      unquote(:"#{name}_template")(assigns)
    end

    Mix.Generator.embed_template(name, contents)
  end)

  # Texts
  [
    {:formatter_exs, get_priv.("formatter.exs")},
    {:nav_html_eex, get_priv.("includes/nav.html.eex")},
    {:base_html_eex, get_priv.("templates/base.html.eex")},
    {:list_html_eex, get_priv.("templates/list.html.eex")},
    {:page_html_eex, get_priv.("templates/page.html.eex")},
    {:post_html_eex, get_priv.("templates/post.html.eex")},
    {:index_md, get_priv.("pages/index.md")},
    {:sample_post_md, get_priv.("posts/sample_post.md")}
  ]
  |> Enum.each(fn {name, contents} ->
    def text(unquote(name)) do
      unquote(:"#{name}_text")()
    end

    Mix.Generator.embed_text(name, contents)
  end)
end
