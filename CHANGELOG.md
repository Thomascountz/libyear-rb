# Changelog

## [Unreleased]

## [0.2.0] - 2026-08-19

### Added

- The report can now be generated in JSON with the `--format json` flag
- The `--sort` flag orders the output by column values (default: `libyear,name`)
- The `--[no-]indirect` flag includes (default) or excludes indirect dependencies in the output
- A library API (`LibyearRb::Runner`) has been extracted for programmatic/scripting use

### Changed

- All results are now sent to formatters, so the report can include both outdated and up-to-date gems
- Gem version metadata is fetched in parallel with per-host worker pools

### Fixed

- When `XDG_CACHE_HOME` is set, the cache directory resolves as a `Pathname` instead of a `String`
- Fetch failures are rescued per dependency, so one error no longer crashes the report

## [0.1.0] - 2026-01-09

### Added

- Initial release of libyear-rb
- Analyze Gemfile.lock to measure dependency freshness in libyears
- Report versions behind (release count) and days/years behind for each dependency
- Support for any RubyGems.org-compatible gem server (private gem servers, mirrors, etc.)
- Historical analysis with `--as-of` flag to analyze dependencies as of a specific date
- Caching of gem metadata to minimize network requests (24-hour TTL)
