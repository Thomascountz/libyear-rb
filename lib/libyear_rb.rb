# frozen_string_literal: true

require_relative "libyear_rb/version"
require_relative "libyear_rb/models"
require_relative "libyear_rb/lockfile_parser"
require_relative "libyear_rb/file_cache"
require_relative "libyear_rb/gem_info_fetcher"
require_relative "libyear_rb/dependency_analyzer"
require_relative "libyear_rb/formatters/formatter"
require_relative "libyear_rb/runner"

require "logger"

module LibyearRb
  class Error < StandardError; end

  class << self
    attr_writer :logger, :cache

    def logger
      @logger ||= Logger.new(File::NULL)
    end

    def cache
      @cache ||= FileCache.new
    end
  end
end
