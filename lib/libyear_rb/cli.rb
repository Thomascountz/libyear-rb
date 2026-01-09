# frozen_string_literal: true

require "optparse"
require "optparse/date"
require "logger"

module LibyearRb
  class CLI
    def run(args)
      config = build_config(args)
      lockfile_contents = read_lockfile(args)

      LibyearRb.analyze(lockfile_contents, config: config)
    end

    private

    def build_config(args)
      config = Config.new
      parser = OptionParser.new do |opts|
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

        opts.on("--as-of DATE", Date, "Analyze dependencies as of the given date (YYYY-MM-DD)") do |date|
          config.as_of = date
        end

        opts.on("--verbose", "Run with verbose logs") do
          config.logger = Logger.new($stdout)
        end

        opts.on("--skip-cache", "Disable reading from and writing to the cache") do
          config.use_cache = false
        end
      end

      begin
        parser.parse!(args)
      rescue OptionParser::ParseError => e
        abort "#{e.message}\n\n#{parser.help}"
      end

      config
    end

    def read_lockfile(args)
      lockfile_path = args[0] || default_lockfile_path

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
