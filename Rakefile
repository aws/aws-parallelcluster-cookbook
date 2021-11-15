#!/usr/bin/env rake
# frozen_string_literal: true

# chefspec task against spec/*_spec.rb
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:chefspec)

# cookstyle rake task
desc 'Cookstyle linter'
task :cookstyle do
  sh 'cookstyle .'
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
task default: %w(cookstyle rubocop chefspec)
