# Serum

**Serum** is a simple static website generator written in [Elixir](http://elixir-lang.org).

Like some of other static website generators, Serum focuses on blogging. And if you know how to write markdown documents and how to handle EEx templates, you can easily build your own website.

Check out the [sample project](https://github.com/Dalgona/serum-sample) and the [website](http://include.iostream.kr/serum-sample)!

## Getting Started

### Requirement

* Elixir 1.3 or newer

    Determined by current development environment. Could support lower versions after tests.

### Initializing and Building the Project

1. Use `git` to clone this repository.

    ```sh
    % git clone https://github.com/Dalgona/Serum.git
    ```

2. Type the commands below to fetch the dependencies and build Serum. The `serum` executable will be created under your PWD.

    ```sh
    % cd Serum
    % mix deps.get
    % mix escript.build
    ```

3. Execute `serum init [directory]` to create a new Serum project at current or specified directory.

    > *It is NOT recommended to initialize a new project to where Serum repository is located.*

    ```sh
    % ./serum init /path/to/project
    ```

4. Type `serum build [directory]` to build the generated project.

    ```sh
    % ./serum build /path/to/project
    ```

    When the build completes, the root of your website will be created under `/path/to/project/site` directory. Copy the contents of this directory to your own www directory, or upload them to the external web hosting service.

### Configuration

When you initialize a new project, Serum will create directory/file structure described below:

```text
/path/to/project/
|-- serum.json
|-- posts
|-- pages
|   |-- pages.json
|   +-- index.md
|-- templates
|   |-- base.html.eex
|   |-- list.html.eex
|   |-- post.html.eex
|   +-- nav.html.eex
|-- assets
|   |-- css
|   |-- js
|   +-- images
+-- media
```

`serum.json` holds information about the current project, which looks like:

```json
{
  "site_name": "New Website",
  "site_description": "Welcome to my website!",
  "author": "Dalgona.",
  "author_email": "dalgona@hontou.moe",
  "base_url": "/site/"
}
```

* `site_name` &mdash; The title of your website.
* `site_description` &mdash; The description of your website. Can be used as a subtitle.
* `author_name` &mdash; The name of author of blog posts.
* `author_email` &mdash; The email address of the author.
* `base_url` &mdash; The base path of your web site. I recommend you to put a trailing `/`.

> These attributes can be referenced by using template tags like `<%= @site_name %>`.

### Adding Pages to Your Website

Inside `pages/` directory you can put source codes for pages other than blog posts. Serum accepts both markdown files(names should end with `.md`) and HTML files(names should end with `.html`), and those files will be applied by `templates/page.html.eex` template, and then combined with `templates/base.html.eex` template and will produce output files into the root directory of website(`site/`).

To display your pages properly, you also need to configure `pages.json` inside `pages/` directory. This file contains titles and other attributes of each page, which look like:

```js
[
  // ...,
  {
    "name": "index",
    "type": "html",
    "title": "Welcome",
    "menu": false,
    "menu_text": "About",
    "menu_icon": "assets/images/menu_index.png"
  },
  // ...
]
```

* `name` &mdash; The filename of page source file.
* `type` &mdash; The extension of page source file. Only "html" and "md" are accepted.
* `title` &mdash; The text that appears on the titlebar of your web browser.
* `menu` &mdash; Sets whether the link of specified page appears in the navigation area. Ignored by some templates.
* `menu_text` &mdash; The link text that appears on the navigation area.
* `menu_icon` &mdash; The path of image file that appears on the navigation area. Ignored by some templates.

> If you do not define properties for a page in `pages.json`, that page WILL NOT included in the website when building the project, even if the source code for that page exists under `pages/` directory.

### Writing a New Post

`posts/` directory holds markdown of your blog posts. All markdown files under this directory must follow the naming rule of `yyyy-MM-dd-hhmm-title-slug.md`, and the very first line of each markdown file must start with `#` character, followed by a space(`'\x20'`), and title of the post, as Serum parses the first line of each file and generates post metadata.

Below is an example of valid markdown file:

`2016-08-01-1946-my-new-post.md:`

```markdown
# Hello! This is My First Post

Lorem ipsum dolor sit amet, consectetur adipiscing ...
```

When building the website, all markdown files under the `posts/` directory are converted into HTML, applied by `templates/post.html.eex` template, and then combined with `templates/base.html.eex` template to produce the output file under `site/posts/` directory. Also, Serum generates `site/posts/index.html`, which is a list of all blog posts.

### Templates

Serum generates web pages by applying four templates: `base.html.eex`, `list.html.eex`, `post.html.eex` and `nav.html.eex`. When the new project is created, the minimally implemented templates are also created under `templates/` directory, which still have all template variables provided by Serum. So you can create your own templates base on those files. The role of each templates are described below:

* `base.html.eex` &mdash; Defines the overall structure and design of your website. The HTML root tag is located inside this template.
* `list.html.eex` &mdash; Template for the list of all registered blog posts.
* `post.html.eex` &mdash; Template for blog posts.
* `page.html.eex` &mdash; Template for pages other than blog posts.
* `nav.html.eex` &mdash; Template for the navigation area of the website.

### Assets and Media

You can put all resources such as stylesheets, scripts and images under `assets/` directory. Serum also creates `css`, `js` `images` directory under `assets/` for the convenience, but it does not matter even if you modify the directory structure as needed. When the site is being built, `assets/` directory itself is copied into `site/assets/` directory, so you can reference the resources like this: `href="<%= @base_url %>assets/css/style.css"`.

All pictures referenced by blog posts should be saved under `media/` directory. Then you can point to that media in the markdown by using `%media:` syntax. For example, the code `![Image](%media:foo.jpg)` will be expanded into `<img src="/base/url/media/foo.jpg" alt="Image">`.

> **NOTE**: Due to the limitations caused by the implementation, using `"` character in the source URL of the image may result in unexpected behavior.

## TODO

* Finding what to do next

## Contact the Developer

* Email: <dalgona@hontou.moe>
* Twitter: [@d57_kr](https://twitter.com/d57_kr)
