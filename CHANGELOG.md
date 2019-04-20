# Serum Changelog

## Unreleased Changes

### Fixed

- Now the Serum development server works on Microsoft Windows, by using a
  platform-independent way to create a temporary directory. (by @kernelgarden)
- Fixed a potential issue which might cause an infinite loop when a Serum
  plugin calls `Serum.File.write/1`.

### Added

- Added `Serum.Plugins.SitemapGenerator` plugin, which generates a `robots.txt`
  and `sitemap.xml` for blog posts. (by @kernelgarden)

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
