# frozen_string_literal: true

require "optparse"
require "date"
require "bundler"
require "logger"

module LibyearRb
  class CLI
    def initialize(argv = ARGV)
      @argv = argv.dup
      @options = {}
      parse_options!
    end

    def run
      lockfile_contents = read_lockfile
      logger = build_logger

      lockfile_parser = LockfileParser.new
      gem_info_fetcher = GemInfoFetcher.new
      dependency_analyzer = DependencyAnalyzer.new(logger: logger)
      reporter = PlaintextReporter.new

      runner = Runner.new(
        lockfile_parser: lockfile_parser,
        gem_info_fetcher: gem_info_fetcher,
        dependency_analyzer: dependency_analyzer,
        reporter: reporter,
        logger: logger
      )

      runner.run(lockfile_contents, as_of: @options[:as_of])
    end

    private

    def build_logger
      return nil unless @options[:verbose]

      Logger.new($stderr)
    end

    def parse_options!
      OptionParser.new do |opts|
        opts.banner = "Usage: libyear-rb [Gemfile.lock] [options]"
        opts.program_name = "libyear-rb"
        opts.version = LibyearRb::VERSION

        opts.on("-h", "--help", "Prints this help") do
          puts opts
          exit
        end

        opts.on("-v", "--version", "Show version") do
          puts "libyear-rb #{LibyearRb::VERSION}"
          exit
        end

        opts.on("--as-of DATE", "Analyze dependencies as of the given date (YYYY-MM-DD)") do |date|
          @options[:as_of] = Date.parse(date)
        rescue ArgumentError
          warn "Invalid date format. Please use YYYY-MM-DD."
          exit 1
        end

        opts.on("--verbose", "Run with verbose logs") do
          @options[:verbose] = true
        end

        opts.separator ""
        opts.separator "Environment variables:"
        opts.separator "  SKIP_CACHE=1    Disable reading to and writing from the libyear-rb cache"
      end.parse!(@argv)
    end

    def read_lockfile
      lockfile_path = @argv[0] || default_lockfile_path

      File.read(lockfile_path)
    rescue Errno::ENOENT
      warn "Lockfile not found at path: #{lockfile_path}"
      exit 1
    end

    def default_lockfile_path
      if defined?(Bundler) && Bundler.respond_to?(:default_lockfile)
        Bundler.default_lockfile.to_s
      else
        "Gemfile.lock"
      end
    end
  end
end
