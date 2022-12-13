# frozen_string_literal: true

source 'https://rubygems.org'

gem 'berkshelf'

group :style do
  gem 'cookstyle', '~> 7.25.9'
  gem 'rake', '~> 13.0.1'
  gem 'rubocop', '~> 1.22.3'
  gem 'rubocop-gitlab-security', '~> 0.1.1'
end

group :test do
  gem 'chefspec', '~> 9.3.0'
  gem 'kitchen-vagrant', '~> 1.13.0'
  gem 'safe_yaml', '~> 1.0.5'
  gem 'test-kitchen', '~> 3.0.0'
end

group :aws do
  gem 'kitchen-ec2'
end
