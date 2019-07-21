# Serum Changelog

## Unreleased Changes

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

### Added

- If you put any extra files and directories in `files/` directory, they will
  be copied to the root of your website. `files/` directory is a good place for
  your favicons, `robots.txt`, and so on.

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
