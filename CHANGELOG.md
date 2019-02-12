# Serum Changelog

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
