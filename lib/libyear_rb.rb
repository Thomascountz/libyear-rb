# frozen_string_literal: true

require_relative "libyear_rb/version"
require_relative "libyear_rb/models"
require_relative "libyear_rb/lockfile_parser"
require_relative "libyear_rb/file_cache"
require_relative "libyear_rb/gem_info_fetcher"
require_relative "libyear_rb/dependency_analyzer"
require_relative "libyear_rb/formatters/formatter"
require_relative "libyear_rb/formatters/plaintext_formatter"
require_relative "libyear_rb/runner"
require_relative "libyear_rb/cli"

require "logger"

module LibyearRb
  class Error < StandardError; end

  class << self
    attr_accessor :logger
    attr_accessor :cache
  end

  self.logger = Logger.new(File::NULL)
  self.cache = FileCache.new
end
