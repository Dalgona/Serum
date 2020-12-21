%{
  title: "Test Webite",
  description: "This is the test website.",
  base_url: "https://www.example.com/test-site",
  authors: %{
    john: %{
      name: "John Doe",
      email: "john.doe@example.com"
    }
  },
  blog: %{
    list_title_all: "All Posts",
    list_title_tag: "Posts Tagged ~s",
    pagination: true,
    posts_per_page: 5
  },
  plugins: [Serum.Plugins.SitemapGenerator]
# ** (TokenMissingError)
