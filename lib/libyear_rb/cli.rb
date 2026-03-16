# frozen_string_literal: true

require "optparse"
require "date"
require "logger"

module LibyearRb
  class CLI
    def initialize(argv = ARGV)
      @argv = argv.dup
      @options = {formatter: "plaintext"}
      parse_options!
    end

    def run
      formatter = Formatter[@options.fetch(:formatter)]
      LibyearRb.logger = Logger.new($stderr) if @options[:verbose]

      lockfile_contents = read_lockfile
      results = Runner.new.run(lockfile_contents, as_of: @options[:as_of])

      formatter.new.generate(results)
    end

    private

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

        opts.on("-f", "--format FORMATTER", "Choose an output formatter.") do |name|
          @options[:formatter] = name
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
      if ENV.key?("BUNDLE_LOCKFILE")
        ENV["BUNDLE_LOCKFILE"]
      elsif ENV.key?("BUNDLE_GEMFILE")
        "#{ENV["BUNDLE_GEMFILE"]}.lock"
      else
        "Gemfile.lock"
      end
    end
  end
end
