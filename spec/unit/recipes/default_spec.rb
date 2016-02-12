require_relative '../spec_helper'

describe 'cfncluster::default' do
  cached(:chef_run) do
    ChefSpec::SoloRunner.new(platform: 'centos', version: '6.6').converge(described_recipe)
  end

  before do
    stub_command("which getenforce").and_return(true)
  end

  it 'requires proper recipes to build a single box stack' do
    expect(chef_run).to include_recipe('cfncluster::gridengine_install')
    expect(chef_run).to include_recipe('cfncluster::openlava_install')
    expect(chef_run).to include_recipe('cfncluster::torque_install')
  end
end