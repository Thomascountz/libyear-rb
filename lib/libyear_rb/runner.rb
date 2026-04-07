# frozen_string_literal: true

module LibyearRb
  class Runner
    def initialize(lockfile_parser:, lockfile_analyzer:, formatter:)
      @lockfile_parser = lockfile_parser
      @lockfile_analyzer = lockfile_analyzer
      @formatter = formatter
    end

    def run(lockfile_contents, as_of: nil)
      lockfile = @lockfile_parser.parse(lockfile_contents)
      results = @lockfile_analyzer.analyze(lockfile, as_of: as_of)
      @formatter.generate(results)
      results
    end
  end
end
