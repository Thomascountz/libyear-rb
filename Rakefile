# frozen_string_literal: true

require "bundler/gem_tasks"

require "minitest/test_task"
Minitest::TestTask.create do |t|
  t.test_globs = ["test/**/test_*.rb"]
  t.test_prelude = 'ENV["SMOKE"] ||= "0"'
end

Minitest::TestTask.create(:smoke) do |t|
  t.test_globs = ["test/test_smoke.rb"]
  t.test_prelude = 'ENV["SMOKE"] = "1"'
end

require "rubocop/rake_task"
RuboCop::RakeTask.new

task default: %i[test rubocop]
