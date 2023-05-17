require 'spec_helper'

# Without this fake test other tests don't work
# Leaving here for the time being, until the entire cookbook is removed
describe 'aws-parallelcluster-config' do
  cached(:chef_run) do
    ChefSpec::Runner.new.converge(described_recipe)
  end
  it 'Does nothing' do
    is_expected.not_to install_package("any")
  end
end
