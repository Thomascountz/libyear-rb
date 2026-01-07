# libyear-rb

A simple measure of dependency freshness for Ruby apps.

```bash
$ libyear-rb
Gem                  Current Current Date Latest   Latest Date Versions Days Years
.................... ....... ............ ........ ........... ........ .... .....
addressable          2.8.7   2024-06-21   2.8.8    2025-11-25         1  522  1.43
bigdecimal           3.3.1   2025-10-09   4.0.1    2025-12-17         4   69  0.19
rails                7.0.0   2021-12-15   7.2.0    2024-08-10        15  968  2.65
System is 4.27 libyears behind
Total releases behind: 20
```

`libyear-rb` tells you how out-of-date your Gemfile.lock is, in libyears (the time between your installed version and the newest version).

## Features

- Analyzes Gemfile.lock to measure dependency freshness
- Reports libyears (time behind) and version distance (releases behind)
- Supports any RubyGems.org-compatible gem server (private gem servers, mirrors, etc.)
- Historical analysis with `--as-of` to see what your dependencies looked like at a specific date
- Caches API responses to minimize network requests

## Installation

```bash
gem install libyear-rb
```

Or add to your Gemfile:

```ruby
gem "libyear-rb"
```

## Usage

Run `libyear-rb` in a directory with a Gemfile.lock, or provide a path:

```bash
libyear-rb                      # Uses ./Gemfile.lock
libyear-rb path/to/Gemfile.lock # Uses specified lockfile
```

### Options

```
--as-of DATE    Analyze dependencies as of the given date (YYYY-MM-DD)
--verbose       Run with verbose logs
--help          Show help
--version       Show version
```

### Historical Analysis

You can analyze what your dependencies looked like at a specific point in time:

```bash
libyear-rb --as-of 2024-01-01
```

## Private Gem Servers

`libyear-rb` supports any gem server with a RubyGems.org-compatible API. It uses your configured gem sources from `~/.gemrc` or environment, so private gems hosted on servers like Gemfury, Artifactory, or self-hosted solutions work automatically.

## Caching

To reduce API requests and improve performance, `libyear-rb` caches gem version metadata for 24 hours.

**Cache location:**
- Uses `$XDG_CACHE_HOME/libyear-rb/` if `XDG_CACHE_HOME` is set
- Otherwise defaults to `~/.cache/libyear-rb/`

Cache files are organized by gem source host, so metadata from different gem servers is stored separately.

**To skip the cache:**
```bash
SKIP_CACHE=1 libyear-rb
```

**To clear the cache:**
```bash
rm -rf ~/.cache/libyear-rb
```

## Alternatives

Other Ruby tools for measuring dependency freshness:

- [libyear-bundler](https://github.com/jaredbeck/libyear-bundler) - The original Ruby libyear implementation. Supports additional metrics like major/minor/patch version deltas and JSON output.
- [bundler-audit](https://github.com/rubysec/bundler-audit) - Focuses on security vulnerabilities rather than freshness, but useful for dependency health.
- [bundle outdated](https://bundler.io/man/bundle-outdated.1.html) - Built into Bundler. Shows outdated gems but doesn't calculate libyears.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt.

To install this gem onto your local machine, run `bundle exec rake install`.

## Acknowledgements

The concept of libyear comes from the technical report "Measuring Dependency Freshness in Software Systems" by J. Cox, E. Bouwers, M. van Eekelen and J. Visser (ICSE 2015).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
