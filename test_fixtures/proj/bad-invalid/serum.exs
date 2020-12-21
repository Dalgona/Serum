%{
  # must be a string
  title: 42,
  description: "This is the test website.",
  base_url: "https://www.example.com/test-site",
  # must be a map
  authors: "John Doe",
  blog: %{
    list_title_all: "All Posts",
    list_title_tag: "Posts Tagged ~s",
    pagination: true,
    posts_per_page: 5
  },
  # must be a list
  plugins: %{}
}
