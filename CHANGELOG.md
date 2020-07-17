# Serum Changelog

## Unreleased Changes

### Added

- Added 3 new configuration items for your Serum project (`serum.exs`), which
  can be used to customize locations for your blog-related pages:

    - `:posts_source` (string, optional) - Path to a directory which holds
      source files for your blog posts. Defaults to `"posts"`.

    - `:posts_path` (string, optional) - Path in a output directory which your
      rendered blog posts will be written to. Defaults to the value of
      `:posts_source`. (i.e. the default value will be `"posts"` if the value
      of `:posts_source` is not explicitly given.)

    - `:tags_path` (string, optional) - Path in an output directory which the
      tag pages will be written to. Defaults to `"tags"`.

## v1.4.1 &mdash; 2020-02-20

### Improved

- Upgraded Floki, the HTML parser library, to 0.26.0, which provides more
  useful functionalities Serum needs.
- Updated some codes that may not work well with the latest version of Floki.
  These codes were causing some noisy warnings during website builds for some
  users, but this issuse is now fixed.

## v1.4.0 &mdash; 2020-01-11

### Added

- Added `open` command to the Serum development server CLI. This command opens
  your website in the default web browser of your desktop environment. Special
  thanks to **[@nallwhy](https://github.com/nallwhy)**!
- Users can now configure the `Serum.Plugins.SitemapGenerator` plugin so that
  it generates entries for pages, posts, or both.

  ```elixir
  %{
    plugins: [
      # Generate sitemap entries for pages only.
      {Serum.Plugins.SitemapGenerator, for: :pages},
      # Generate sitemap entries for posts only.
      {Serum.Plugins.SitemapGenerator, for: :posts},
      # Generate sitemap entries for both pages and posts.
      {Serum.Plugins.SitemapGenerator, for: [:pages, :posts]},
      # Generate sitemap entries for posts only. (Backward comptatibility)
      Serum.Plugins.SitemapGenerator
    ]
  }
  ```

### Changed

- The `Serum.Plugins.SitemapGenerator` plugin no longer generates `robots.txt`
  file. Create and put your own `robots.txt` to your `files/` directory.

## v1.3.0 &mdash; 2019-11-28

### Fixed

- Fixes an issue which ignored custom template settings for blog posts.

### Improved

- Serum now displays relative paths from the current working directory, instead
  of absolute paths, whenever possible.

- Support for nested includes has been added. Now users can use the `include/1`
  macro inside their includes. Self-including or circular includes are
  intentionally not supported and these will result in errors.

- Serum provides more options for the length of preview text for each blog post.

    - `preview_length: {:chars, 200}` tells Serum to take the first 200
      characters from a blog post to generate a preview text. The next two
      options should be self-explanatory now.

    - `preview_length: {:words, 20}`

    - `preview_length: {:paragraphs, 1}` (Serches for `<p>` tags.)

    - Of course, you can still use the old value: `preview_length: 200`.

- Serum no longer emits ANSI escape sequences by default when the output is not
  a terminal. (i.e. when the output is written to a file, or when the output is
  piped to another program.)

  Run any Serum Mix tasks with `--color` or `--no-color` option to override
  this behavior.

### Added

- Users can now pass an arbitrary argument to a Serum plugin.

  The accepted value of plugin argument is defined by the plugin author, and
  this can be used to configure how the plugin should work.

- This update introduces a new `render/2` template helper.

  The `render/2` helper works like the existing `include/1` helper. However,
  unlike `include/1`, this helper dynamically renders the given include when
  the calling template/include is being rendered.

### Changed

- **BREAKING CHANGES for plugin authors**: The following plugin callbacks now
  accept one more argument: `args`.

    - `build_started/3`
    - `reading_pages/2`
    - `reading_posts/2`
    - `reading_templates/2`
    - `processing_page/2`
    - `processing_post/2`
    - `processing_template/2`
    - `processed_page/2`
    - `processed_post/2`
    - `processed_template/2`
    - `processed_list/2`
    - `processed_pages/2`
    - `processed_posts/2`
    - `rendering_fragment/3`
    - `rendered_fragment/2`
    - `rendered_page/2`
    - `wrote_file/2`
    - `build_succeeded/3`
    - `build_failed/4`
    - `finalizing/3`

    Please update your plugins by implementing the new callbacks above.
    Existing callbacks will still be supported, but they will be removed in
    later releases.

## v1.2.0 &mdash; 2019-08-04

### Fixed

- Fixed an issue where the Serum development server crashes if the file system
  watcher backend is not available on the user's system. The server will work
  now, but features related to automatic reloading will be disabled.

- Now the prompt text (`8080>`) in the Serum development server CLI will catch
  up the console output, instead of lagging behind.

- Updated one of Serum's dependencies. Users will no longer see strange errors
  from "Tzdata" once a day.

### Improved

- `Serum.File.read/1` now checks if the value of `src` key in the input struct
  is nil. An error will be returned if so. Likewise, `Serum.File.write/1`
  checks the value of `dest` key.

- Now you can add any user-defined metadata to your pages and posts. Just put
  some lines like `key: value` in the header, and these metadata will be
  available at `@page.extras` (or `@post.extras`) in your templates.

### Added

- If you put any extra files and directories in `files/` directory, they will
  be copied to the root of your website. `files/` directory is a good place for
  your favicons, `robots.txt`, and so on.

- Added support for custom templates. Pages and blog posts now recognize the
  `template` key in their headers.

### Changed

- Docs: Marked some docs for internal modules as hidden, and organized
  moduledocs by categories. Hidden docs are still accessible via source codes.

- Overhauled codes which start and stop the Serum development server. The
  temporary output directory created by the server will now be cleaned up in
  most exit situations. Additionally, users will be able to see less horrifying
  error output when the server failed to start.

  For developers: The Serum development server and its command line interface
  have been decoupled. Starting the server with `Serum.DevServer.run/2` does
  not take you to the command line interface. Instead, you can call
  `Serum.DevServer.Prompt.start/1` to enter the server CLI.

  There are now two ways to get out of the CLI: The `quit` command stops the
  development server and returns. If you want to keep the server running, use
  the `detach` command. You can later enter the CLI again using the same
  `Serum.DevServer.Prompt.start/1` function.

- Changed format of the message output, with a new internal module which
  controls the console output.

    - TODO: Disable emitting ANSI escape sequences when the output device is
      not a terminal.

- If there are more than one _identical_ errors, only one of them will be
  displayed. Usually these errors are from _one_ source and they will be gone
  all together if one error in the project source gets fixed.

## v1.1.0 &mdash; 2019-05-18

### Fixed

- The development server now quits gracefully when the user sends EOF (Ctrl+D)
  (Issue #45)

### Added

- **Serum now supports themes!** Please visit the official website to learn
  more about Serum themes.

- Installer: Added `serum.new.theme` Mix task, which helps you create a new
  Serum theme project.

- The following optional callbacks were added for plugins.
    - `processed_pages/1`
    - `processed_posts/1`
    - `rendering_fragment/2`

- Added `Serum.HtmlTreeHelper` module, which provides `traverse/2` and
  `traverse/3` function. You will find this module useful when you need to
  manipulate HTML trees from your plugins.

### Changed

- The behavior of the Table of Contents plugin has slightly changed.

    - This plugin no longer prepends a `<a name="...">` tag to each heading
      tag. Instead, it will use the `id` attribute of each one of them. If a
      tag does not have an `id`, it will be set appropriately by the plugin.

    - The TOC element (`ul.serum-toc`) will also be given an ID (`#toc`), so
      that you can make hyperlinks back to the list.

- Serum now automatically generates an `id` attribute for each HTML heading
  tag. (by @igalic, Issue #44)

    - If a heading tag already has an ID, it won't be modified.
    - Each ID is generated based on the tag's text content.
    - Generated IDs are always unique. If a duplicate ID is to be generated,
      a number will be appended.

## v1.0.0 &mdash; 2019-05-03

This is the first official release of Serum! 🎉

### Fixed

- Do not generate post lists when there is no blog post. Until now, an empty
  post list has been generated anyway. (by @igalic, PR #41)
- Lots of refactoring and bug fixes which can improve reliability.

### Changed

- Serum now exits with an error when trying to include a template which does
  not exist in `includes/` directory.

### Removed

- Completely removed support for `serum.json` file. You must use `seurm.exs`
  instead.

## v1.0.0-pre.0 &mdash; 2019-04-23

This is the first pre-release of Serum v1.0.0. I will mostly focus on stability
and code coverage until the final release.

### Removed

- `serum.json` is no longer supported. Serum will exit with an error when
  trying to load one. Migrate to `serum.exs` now. JSON files won't be
  recognized when Serum v1.0.0 is released.

## v0.13.0 &mdash; 2019-04-22

### Fixed

- Now the Serum development server works on Microsoft Windows, by using a
  platform-independent way to create a temporary directory.
  (by @kernelgarden, PR #32)
- Fixed a potential issue which might cause an infinite loop when a Serum
  plugin calls `Serum.File.write/1`.
- Fixed a potential crash which can happen if the destination directory has no
  write permission. Serum now exits gracefully with error messages.
- Serum no longer crashes when the destination directory is not writable.
  Instead, it exits gracefully with an error message. (#35)
- The values of `@all_pages` and `@all_posts` variables in EEx templates match
  the latest official documentation. (#36)

### Changed

- The table of contents plugin now preserves markup inside source `<h1>`~`<h6>`
  tags when building TOC list items.

### Added

- Added `Serum.Plugins.SitemapGenerator` plugin, which generates a `robots.txt`
  and `sitemap.xml` for blog posts. (by @kernelgarden, PR #33)

## v0.12.0 &mdash; 2019-04-17

### Fixed

- Fixed a problem that `Serum.Plugins.TableOfContents` can generate reversed
  HTML trees.
- Changed the script injected by `Serum.Plugin.LiveReloader` so that the scroll
  offset is preserved after page reloads.
- Fix `Serum.Project.new/1` which may cause issues if invalid date format
  format string is in `serum.exs`.

### Changed

- Serum now requires Elixir v1.7.0 or newer.
- Minor improvements in internal code base structure.

## v0.11.0 &mdash; 2019-04-14

### Added

- Serum now ships with "Table of Contents" plugin. More of essential plugins
  are coming in the future!
- Added a live reloader script injector plugin to support the Serum development
  server. This plugin is set to run only if `Mix.env() == :dev` when you create
  a new Serum project from now on.

### Changed

- You can now let Serum plugins be loaded only in specified Mix environments.
  Please refer to the module documentation of `Serum.Plugin` for details.
- The Serum development server now automatically rebuilds your project when
  the source code has changed, and signals any open web browers to reload the
  page. Your web browser must support the WebSocket API.

## v0.10.0 &mdash; 2019-04-12

### Fixed

- `Serum.File.write/1` now properly closes a file. This problem caused the
  Serum development server to crash after dozens of project rebuilds.
- Fixed a potential issue which can happen when building a newly created
  Serum project.

### Added

- Added support for Elixir-based project definition file (`serum.exs`).
  `mix serum.new` now generates `serum.exs` instead of `serum.json`.
- Added support for Serum plugins. Several basic plugins will be included
  in later releases. :)

### Deprecated

- Deprecated processing of JSON project definition file (`serum.json`) in
  favor of the new Elixir format.

## v0.9.0 &mdash; 2019-02-26

### Fixed

- Fixed Elixir 1.8.x compatibility of `TemplateCompiler`.
- Fixed `mix serum.new` generating incorrect dependency information.

### Changed

- Upgraded `microscope` which now uses Cowboy 2.6.1.
- Minor refactoring and internal structure improvements.

## v0.8.2 &mdash; 2019-02-14

### Fixed

- Changed the backend of filesystem watcher from `fs` to `file_system`.
  This will fix development server issues on macOS.

### Changed

- Serum now tries to compile the project codes (in `lib/`)
  when the user invokes `mix serum.build` or `mix serum.server` task.
- Refactored (maybe reimplemented) template helper macros except `include/1`.
  This change may not affect the existing behavior.

## v0.8.1 &mdash; 2019-02-13

### Fixed

- Now `serum.gen.post` generates well-formed tags header.

### Added

- Added missing `mix serum` task.

## v0.8.0 &mdash; 2019-02-13

### Changed

- Installation method has changed.
  - escript is no longer used. Install `serum_new` archive from external
    source (e.g. Hex) and run `mix serum.new` to create a new Serum project.
  - A Serum project is also a Mix project, with `serum` added as a dependency.
    Run `mix do deps.get, deps.compile` to install Serum under that project.
  - Then existing Serum tasks will be available as Mix tasks.
    (e.g. `mix serum.build`, etc.)

- Due to the above change, every Serum project now requires its own
  `mix.exs` file.

## v0.7.0 &mdash; 2019-02-12

### Added

- An optional project property `server_root` is added in `serum.json`.
- A list of image URLs (relative to `@site.server_root`) are available through
  `@page.images` in `base`, `list`, `page`, `post` templates and includes.

### Changed

- Regex pattern requirement for `base_url` project property has changed.
  Now it must start and end with a slash (`/`).

## v0.6.1 &mdash; 2019-01-01

### Changed

- Changed the minimum Elixir version requirement from 1.4 to 1.6.

## v0.6.0 &mdash; 2019-01-01

### Changed

- Massive internal refactoring
- Minor performance optimization

## v0.5.0 &mdash; 2018-12-11

- Initial version; began changelog tracking.
