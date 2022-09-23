require 'chefspec'
require 'chefspec/berkshelf'

# Require all our libraries
Dir['libraries/*.rb'].each { |f| require File.expand_path(f) }

RSpec.configure do |config|
  config.color = true               # Use color in STDOUT
  config.formatter = :documentation # Use the specified formatter
  config.log_level = :error         # Avoid deprecation notice SPAM
end
