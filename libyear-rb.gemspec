# frozen_string_literal: true

require_relative "lib/libyear_rb/version"

Gem::Specification.new do |spec|
  spec.name = "libyear-rb"
  spec.version = LibyearRb::VERSION
  spec.authors = ["Thomas Countz", "Benjamin Quorning"]
  spec.email = ["thomascountz@gmail.com", "bquorning@zendesk.com"]

  spec.summary = "A simple measure of dependency freshness"
  spec.description = "libyear-rb analyzes your Gemfile.lock and tells you how out-of-date your dependencies are, " \
                     "in libyears (the time between your installed version and the newest version)."
  spec.homepage = "https://github.com/thomascountz/libyear-rb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/thomascountz/libyear-rb/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .standard.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "gems", "~> 1.3"
  spec.add_dependency "logger"
end
