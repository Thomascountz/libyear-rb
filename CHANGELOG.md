# Changelog

## [Unreleased]

## [0.1.0] - 2025-01-09

### Added

- Initial release of libyear-rb
- Analyze Gemfile.lock to measure dependency freshness in libyears
- Report versions behind (release count) and days/years behind for each dependency
- Support for any RubyGems.org-compatible gem server (private gem servers, mirrors, etc.)
- Historical analysis with `--as-of` flag to analyze dependencies as of a specific date
- Caching of gem metadata to minimize network requests (24-hour TTL)
