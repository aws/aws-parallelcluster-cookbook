require 'chefspec'
require 'chefspec/berkshelf'

require_relative '../../../cookbooks/aws-parallelcluster-shared/spec/spec_helper'

RSpec.configure do |c|
  c.before(:all) do
    ChefSpec::SoloRunner.new.converge('aws-parallelcluster-config')
  end
end
