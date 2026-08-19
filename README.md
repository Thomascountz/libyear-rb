# libyear-rb

A measure of dependency freshness for Gemfile.lock. Tells you how out-of-date your dependencies are, in [libyears](https://libyear.com/) by comparing the release date of the locked version to the latest available version.

## Installation

To use the CLI, install the gem:

```bash
gem install libyear-rb
```

```bash
mise install gem:libyear-rb
```

To use programmatically, add to your Gemfile:

```ruby
gem "libyear-rb"
```

```ruby
require "bundler/inline"
gemfile do
  source "https://rubygems.org"
  gem "libyear-rb"
end
```

## Usage

### As a CLI

Run `libyear-rb` in a directory with a Gemfile.lock, or provide a path:

```bash
libyear-rb                      # Uses ./Gemfile.lock
libyear-rb path/to/Gemfile.lock # Uses specified lockfile
```

```
Gem                  Current Current Date Latest   Latest Date Versions Days Years
.................... ....... ............ ........ ........... ........ .... .....
addressable          2.8.7   2024-06-21   2.8.8    2025-11-25         1  522  1.43
bigdecimal           3.3.1   2025-10-09   4.0.1    2025-12-17         4   69  0.19
rails                7.0.0   2021-12-15   7.2.0    2024-08-10        15  968  2.65
System is 4.27 libyears behind
Total releases behind: 20
```

Options:

```
--as-of DATE        Only consider versions released before DATE (YYYY-MM-DD)
--format FORMATTER  Choose an output formatter (plaintext, json) (default: plaintext)
--sort SPEC         Sort by comma-separated columns (default: libyear,name)
--[no-]indirect     Include indirect dependencies in output (on by default)
--verbose           Run with logs
--help              Show help
--version           Show version
```

#### Sorting

The `--sort` flag accepts a comma-separated list of columns. Each column has a
fixed direction: `name` is ascending, while `latest-date`, `versions`, and
`libyear` are descending. Later columns are used to break ties.

```bash
libyear-rb --sort versions,name   # most releases behind first, then by name
libyear-rb --sort libyear         # most libyears behind first
```

#### Formatters

- `plaintext` (default) — prints a human-readable table to stdout, listing only outdated gems.
- `json` — prints a machine-readable JSON document to stdout, listing every gem along with a summary.

```bash
libyear-rb --format json
```

### As a Library

```ruby
require "libyear_rb"

results = LibyearRb::Runner.new.run(File.read("Gemfile.lock"))

results.each do |r|
  puts "#{r.name}: #{r.version_distance} versions, #{r.libyear_in_days} days behind"
end
```

Configure the cache or logger before use:

```ruby
LibyearRb.cache = LibyearRb::FileCache.new(skip_cache: true)
LibyearRb.logger = Logger.new($stderr)
```

## Private Gem Servers

`libyear-rb` supports any gem server with a RubyGems.org-compatible API. It uses your configured gem sources from `~/.gemrc` (`gem sources`) or environment, so private gems hosted on servers like Gemfury, Artifactory, or self-hosted solutions work automatically.

## Caching

To reduce API requests and improve performance, `libyear-rb` caches gem version metadata for 24 hours.

Cache location:
- Gem info is cached under `$XDG_CACHE_HOME/libyear-rb/` (or `~/.cache/libyear-rb/` if `XDG_CACHE_HOME` is not set), with a subdirectory for each gem host.

To skip the cache:
```bash
SKIP_CACHE=1 libyear-rb
```

To clear the cache:
```bash
rm -rf ~/.cache/libyear-rb
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. 

### Commands

```bash
# Setup development environment
bin/setup

# Run tests
rake test

# Run linter
rake rubocop

# Install gem locally
bundle exec rake install
```

## Acknowledgements

The concept of libyear comes from the technical report "Measuring Dependency Freshness in Software Systems" by J. Cox, E. Bouwers, M. van Eekelen and J. Visser (ICSE 2015).

## Alternatives

- [libyear-bundler](https://github.com/jaredbeck/libyear-bundler) - The original Ruby libyear implementation. Supports additional metrics like major/minor/patch version deltas and JSON output.
- [bundler-audit](https://github.com/rubysec/bundler-audit) - Focuses on security vulnerabilities rather than freshness.
- [bundle outdated](https://bundler.io/man/bundle-outdated.1.html) - Built into Bundler. Shows outdated gems but doesn't calculate libyears.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
