require_relative '../spec_helper'

describe 'cfncluster::base_config' do

  before do
    stub_command("which getenforce").and_return(true)
  end

  before do
    stub_command("grep -qx configure-pat.sh /etc/rc.local").and_return(true)
  end

  context 'using MasterServer for cfn_node_type' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: '6.6') do |node|
        node.set['cfncluster']['cfn_node_type'] = 'MasterServer'
      end.converge(described_recipe)
    end

    it 'includes the _master_base_config receipe' do
      expect(chef_run).to include_recipe('cfncluster::_master_base_config')
    end
  end

  context 'using ComputeFleet for cfn_node_type' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: '6.6') do |node|
        node.set['cfncluster']['cfn_node_type'] = 'ComputeFleet'
      end.converge(described_recipe)
    end

    it 'includes the _compute_base_config receipe' do
      expect(chef_run).to include_recipe('cfncluster::_compute_base_config')
    end

  end

  context 'using nil for cfn_node_type' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: '6.6') do |node|
        node.set['cfncluster']['cfn_node_type'] = nil
      end.converge(described_recipe)
    end

    it 'raises an exception' do
      expect { chef_run }
        .to raise_error(RuntimeError, "cfn_node_type must be MasterServer or ComputeFleet")
    end
  end

  context 'using foobar for cfn_node_type' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: '6.6') do |node|
        node.set['cfncluster']['cfn_node_type'] = 'foobar'
      end.converge(described_recipe)
    end

    it 'raises an exception' do
      expect { chef_run }
        .to raise_error(RuntimeError, "cfn_node_type must be MasterServer or ComputeFleet")
    end
  end

end