defmodule Serum.Payload do
  @moduledoc """
  This module contains static data used to initialize a new Serum project.
  """

  @spec template_base() :: String.t
  def template_base(), do: """
  <!doctype html>
  <html>
    <head>
      <meta charset="utf-8">
      <title><%= page_title %> - <%= site_name %></title>
    </head>
    <body>
      <h1><a href="<%= base() %>"><%= site_name %></a></h1>
      <p><%= site_description %></p>
      <%= navigation %>
      <%= contents %>
    </body>
  </html>
  """

  @spec template_nav() :: String.t
  def template_nav(), do: """
  <ul>
    <li><a href="<%= page "index" %>">Home</a></li>
    <li><a href="<%= base "posts" %>">Posts</a></li>
  </ul>
  """

  @spec template_list() :: String.t
  def template_list(), do: """
  <h2><%= header %></h2>
  <ul>
    <%= for x <- posts do %>
      <li>
        <p><a href="<%= x.url %>"><%= x.title %></a>
        &mdash;
        <span class="date"><%= x.date %></span></p>
        <p><%= x.preview_text %></p>
      </li>
    <% end %>
  </ul>
  """

  @spec template_page() :: String.t
  def template_page(), do: """
  <%= contents %>
  """

  @spec template_post() :: String.t
  def template_post(), do: """
  <h1><%= title %></h1>
  <p>Posted on <%= date %> by <%= author %></p>
  <%= unless Enum.empty? tags do %>
    <p>Tags:</p>
    <ul>
      <%= for t <- tags do %>
        <li><a href=\"<%= t.list_url %>\"><%= t.name %></a></li>
      <% end %>
    </ul>
  <% end %>
  <%= contents %>
  """
end
