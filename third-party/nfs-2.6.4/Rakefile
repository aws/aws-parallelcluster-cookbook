#!/usr/bin/env rake

# chefspec task against spec/*_spec.rb
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:chefspec)

# cookstyle
desc 'Ruby style guide linter'
task :cookstyle do
  sh 'cookstyle --fail-level W'
end

# test-kitchen task
begin
  require 'kitchen/rake_tasks'
  Kitchen::RakeTasks.new
rescue LoadError
  puts '>>>>> Kitchen gem not loaded, omitting tasks' unless ENV['CI']
end

# default tasks are quick, commit tests
task default: %w(cookstyle chefspec)
