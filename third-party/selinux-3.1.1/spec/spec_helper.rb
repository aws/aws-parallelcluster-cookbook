require 'chefspec'
require 'chefspec/berkshelf'

require_relative '../libraries/selinux_file_helper'
require_relative '../libraries/selinux_module_helper'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
end

# EOF
