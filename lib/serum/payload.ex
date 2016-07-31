defmodule Serum.Payload do
  def template_base() do
    ~s(<!doctype html>\n) <>
    ~s(<html>\n) <>
    ~s(<head>\n) <>
    ~s(<meta charset="utf-8">\n) <>
    ~s(<title><%= @site_name => - <%= @page_title %></title>\n) <>
    ~s(</head>\n) <>
    ~s(<body>\n) <>
    ~s(<h1><a href="<%= @base_url %>"><%= @site_name %></a></h1>\n) <>
    ~s(<p><%= @site_description %></p>\n) <>
    ~s(<%= @navigation %>\n) <>
    ~s(<%= contents %>\n) <>
    ~s(</body>\n) <>
    ~s(</html>\n)
  end

  def template_nav() do
    ~s(<ul>\n) <>
    ~s(<%= for x <- @pages do %>\n) <>
    ~s(<li><a href="<%= @base_url %><%= x.name %>.html"><%= x.menu_text %></a></li>\n) <>
    ~s(<% end %>\n) <>
    ~s(<li><a href="<%= @base_url %>posts/">Posts</a></li>\n) <>
    ~s(</ul>\n)
  end

  def template_list() do
    ~s(<ul>\n) <>
    ~s(<%= for x <- @posts do %>\n) <>
    ~s(<li><a href="<%= x.file %>"><%= x.title %></a>&nbsp;&mdash;&nbsp;<span class="date"><%= x.date %></span></li>\n) <>
    ~s(<% end %>\n) <>
    ~s(</ul>\n)
  end

  def template_post() do
    ~s(<h1><%= title %></h1>\n) <>
    ~s(<p>Posted on <%= @date %> by <%= @author %></p>\n) <>
    ~s(<%= contents %>\n)
  end
end
