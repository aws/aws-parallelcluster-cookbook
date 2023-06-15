require 'chefspec'
require 'chefspec/berkshelf'

require_relative '../../aws-parallelcluster-shared/spec/spec_helper'

RSpec.configure do |c|
  c.before(:all) do
    ChefSpec::SoloRunner.new.converge('aws-parallelcluster-slurm')
  end
end
