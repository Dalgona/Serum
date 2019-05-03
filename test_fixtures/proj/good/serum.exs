%{
  site_name: "Test Webite",
  site_description: "This is the test website.",
  server_root: "https://www.example.com",
  base_url: "/test-site/",
  author: "John Doe",
  author_email: "john.doe@example.com",
  date_format: "{YYYY}-{0M}-{0D}",
  list_title_all: "All Posts",
  list_title_tag: "Posts Tagged ~s",
  pagination: false,
  posts_per_page: 5,
  preview_length: 200,
  plugins: [Serum.Plugins.SitemapGenerator]
}
