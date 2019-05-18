defmodule Serum.Template.Helpers do
  @moduledoc false

  _moduledocp = """
  Provides helper macros for EEx templates.

  This module provides some helper macros for use in any templates in your
  Serum project, mainly related to accessing website resources.

  This module is automatically required and imported when each template
  is compiled, reducing some boilerplate codes required for creating a useful
  template. However, name conflicts can occur if you import other modules
  exporting functions/macros with the same names.
  """

  @doc "Returns the value of `@site.base_url`."

  defmacro base do
    quote do: unquote(base!())
  end

  @doc """
  Returns the path relative to `@site.base_url`.

  ## Example

      # Suppose @site.base_url is "/mysite/".
      <%= base("/path/to/some_file.txt") %>
      ==> /mysite/path/to/some_file.txt
  """

  defmacro base(arg) do
    quote do: Path.join(unquote(base!()), unquote(arg))
  end

  @doc """
  Returns the URL of the given page.

  ## Examples

      # Suppose @site.base_url is "/mysite/".
      <%= page("profile/my-projects") %>
      ==> /mysite/profile/my-projects.html

  Do not append `.html` extension at the end of `arg`.

      <%= page("profile/my-projects.html") %>
      ==> /mysite/profile/my-projects.html.html (bad)
  """

  defmacro page(arg) do
    quote do: Path.join(unquote(base!()), unquote(arg) <> ".html")
  end

  @doc """
  Returns the URL of the given blog post.

  ## Examples

      # Suppose @site.base_url is "/mysite/".
      <%= post("2019-02-14-sample-post") %>
      ==> /mysite/posts/2019-02-14-sample-post.html
  """

  defmacro post(arg) do
    quote do: Path.join([unquote(base!()), "posts", unquote(arg) <> ".html"])
  end

  @doc """
  Returns the URL of the given asset.

  ## Examples

      # Suppose @site.base_url is "/mysite/".
      <%= asset("images/icon.png") %>
      ==> /mysite/assets/images/icon.png
  """

  defmacro asset(arg) do
    quote do: Path.join([unquote(base!()), "assets", unquote(arg)])
  end

  defp base!, do: quote(do: get_in(var!(assigns), [:site, :base_url]))
end
