%{
  # must be a string
  site_name: 42,
  site_description: "This is the test website.",
  server_root: "https://www.example.com",
  base_url: "/test-site/",
  # must be a string
  author: fn -> "John Doe" end,
  author_email: "john.doe@example.com",
  date_format: "{YYYY}-{0M}-{0D}",
  list_title_all: "All Posts",
  list_title_tag: "Posts Tagged ~s",
  pagination: false,
  # must be greater than 0
  posts_per_page: -65535,
  # must be an integer
  preview_length: "one thousand characters",
  # must be a list
  plugins: %{}
}
