# frozen_string_literal: true

source 'https://rubygems.org'

gem 'berkshelf'

group :style do
  gem 'foodcritic', '~> 16.2.0'
  gem 'rake', '~> 13.0.1'
  gem 'rubocop', '~> 0.80.1'
  gem 'rubocop-gitlab-security'
end

group :test do
  gem 'chefspec', '~> 9.1.0'
  gem 'kitchen-vagrant', '~> 1.6.1'
  gem 'safe_yaml', '~> 1.0.5'
  gem 'test-kitchen', '~> 2.3.4'
end

group :aws do
  gem 'kitchen-ec2'
end
