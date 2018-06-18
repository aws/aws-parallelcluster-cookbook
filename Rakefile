#!/usr/bin/env rake

# chefspec task against spec/*_spec.rb
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:chefspec)

# foodcritic rake task
# Rule FC061 was removed to avoid strict release number format x.y.z
# and to allow alpha/beta/rc versions
desc 'Foodcritic linter'
task :foodcritic do
  sh 'foodcritic -f correctness . --tags ~FC061'
end

# rubocop rake task
desc 'Ruby style guide linter'
task :rubocop do
  sh 'rubocop --fail-level W'
end

# test-kitchen task
begin
  require 'kitchen/rake_tasks'
  Kitchen::RakeTasks.new
rescue LoadError
  puts '>>>>> Kitchen gem not loaded, omitting tasks' unless ENV['CI']
end

# default tasks are quick, commit tests
task default: %w[foodcritic rubocop chefspec]
