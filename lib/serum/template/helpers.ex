defmodule Serum.Template.Helpers do
  @moduledoc """
  A collection of helper macros for EEx templates.

  This module provides some helper macros for use in any templates in your
  Serum project, mainly related to accessing website resources.

  This module is automatically required and imported when each template
  is compiled, reducing some boilerplate codes required for creating a useful
  template. However, name conflicts can occur if you import other modules
  exporting functions/macros with the same names.

  There are some assumptions in the rest of this documentation:

  - In project configuration, `:base_url` is set to
    `"https://example.com/mysite"`, i.e. in EEx templates, `@project.base_url`
    returns `#URI<"https://example.com/mysite">`.
  - In blog configuration, `:posts_path` is set to `"posts"`.
  """

  require Serum.V2.Result, as: Result
  alias Serum.Renderer
  alias Serum.Template.Storage, as: TS
  alias Serum.V2.Error

  @doc """
  Returns a path relative to `@project.base_url.path`.

  ## Example

      <%= url("/path/to/some_file.txt") %>
      ==> /mysite/path/to/some_file.txt
  """
  defmacro url(arg) do
    quote do: Path.join(unquote(base!()), unquote(arg))
  end

  @doc """
  Returns the URL of the given page.

  ## Examples

      <%= page_url("profile/my-projects") %>
      ==> /mysite/profile/my-projects.html

  Do not append `.html` extension at the end of `arg`.

      <%= page_url("profile/my-projects.html") %>
      ==> /mysite/profile/my-projects.html.html (probably not a desired result)
  """
  defmacro page_url(arg) do
    quote do: Path.join(unquote(base!()), unquote(arg) <> ".html")
  end

  @doc """
  Returns the URL of the given blog post.

  ## Examples

      <%= post_url("2019-02-14-sample-post") %>
      ==> /mysite/posts/2019-02-14-sample-post.html

  Do not append `.html` extension at the end of `arg`.

      <%= post_url("2019-02-14-sample-post.html") %>
      ==> /mysite/posts/2019-02-14-sample-post.html.html (probably not a desired result)
  """
  defmacro post_url(arg) do
    quote do
      Path.join([
        unquote(base!()),
        var!(assigns)[:project].blog.posts_path,
        unquote(arg) <> ".html"
      ])
    end
  end

  @doc """
  Returns the URL of the given asset.

  ## Examples

      <%= asset_url("images/icon.png") %>
      ==> /mysite/assets/images/icon.png
  """
  defmacro asset_url(arg) do
    quote do: Path.join([unquote(base!()), "assets", unquote(arg)])
  end

  @doc """
  Dynamically renders includes with given arguments.

  The `args` parameter must be a keyword list.
  """
  def render(name, args \\ []) do
    Result.run do
      template <- TS.get(name, :include)
      ensure_keyword(args)
      Renderer.render_fragment(template, args: args)
    end
    |> case do
      {:ok, html} -> html
      {:error, %Error{}} = error -> raise Serum.Result.get_message(error, 0)
    end
  end

  @spec ensure_keyword(term()) :: Result.t({})
  defp ensure_keyword(args) do
    if Keyword.keyword?(args) do
      Result.return()
    else
      Result.fail("'args' must be a keyword list, got: #{inspect(args)}")
    end
  end

  defp base!, do: quote(do: var!(assigns)[:project].base_url.path)

  defmacro include(_) do
    raise "the include/1 macro is expanded by the Serum template compiler " <>
            "and it must not be called directly"
  end
end
