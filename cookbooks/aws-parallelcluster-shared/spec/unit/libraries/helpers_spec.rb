require_relative '../../../libraries/helpers'
require 'spec_helper'

describe 'login_nodes_enabled?' do
  let(:node) { Chef::Node.new }
  let(:shared_dir) { '/opt/parallelcluster/shared' }
  let(:lt_config_path) { "#{shared_dir}/launch-templates-config.json" }

  before { node.override['cluster']['shared_dir'] = shared_dir }

  it 'raises an error when the launch templates config file does not exist' do
    allow(::File).to receive(:exist?).with(lt_config_path).and_return(false)
    expect { login_nodes_enabled? }.to raise_error(/does not exist/)
  end

  it 'returns true when the config contains a non-empty LoginPools map' do
    allow(::File).to receive(:exist?).with(lt_config_path).and_return(true)
    allow(::File).to receive(:read).with(lt_config_path).and_return('{"LoginPools": {"pool-0": {}}}')
    expect(login_nodes_enabled?).to be true
  end

  it 'returns false when LoginPools is present but empty' do
    allow(::File).to receive(:exist?).with(lt_config_path).and_return(true)
    allow(::File).to receive(:read).with(lt_config_path).and_return('{"LoginPools": {}}')
    expect(login_nodes_enabled?).to be false
  end

  it 'returns false when LoginPools key is absent' do
    allow(::File).to receive(:exist?).with(lt_config_path).and_return(true)
    allow(::File).to receive(:read).with(lt_config_path).and_return('{"Queues": {"queue-0": {}}}')
    expect(login_nodes_enabled?).to be false
  end

  it 'returns false when the substring LoginPools appears outside of a real key' do
    allow(::File).to receive(:exist?).with(lt_config_path).and_return(true)
    allow(::File).to receive(:read).with(lt_config_path).and_return('{"Queues": {"LoginPools-decoy": {}}}')
    expect(login_nodes_enabled?).to be false
  end

  it 'raises an error when the config is not valid JSON' do
    allow(::File).to receive(:exist?).with(lt_config_path).and_return(true)
    allow(::File).to receive(:read).with(lt_config_path).and_return('{not valid json')
    expect { login_nodes_enabled? }.to raise_error(JSON::ParserError)
  end
end

describe 'is_custom_node?' do
  let(:node) { Chef::Node.new }
  let(:default_base) { 'DEFAULT_BASE_URL' }
  let(:default_package) { "#{default_base}/node/DEFAULT_NODE_PACKAGE" }

  before { node.default['cluster']['custom_node_package'] = default_package }

  it 'returns false when the package equals the shipped default' do
    node.override['cluster']['custom_node_package'] = default_package
    expect(is_custom_node?).to be false
  end

  it 'returns false when the package is nil' do
    expect(is_custom_node?).to be false
  end

  it 'returns false when the package is empty' do
    node.override['cluster']['custom_node_package'] = ''
    expect(is_custom_node?).to be false
  end

  it 'returns true when the customer supplies a different package' do
    node.override['cluster']['custom_node_package'] = 'CUSTOM_NODE_PACKAGE'
    expect(is_custom_node?).to be true
  end

  it 'returns true when only the path differs but the base is the same' do
    node.override['cluster']['custom_node_package'] = "#{default_base}/other/CUSTOM_NODE_PACKAGE"
    expect(is_custom_node?).to be true
  end
end

describe 'cluster_readiness_check_enabled?' do
  let(:node) { Chef::Node.new }

  %w(true TRUE True).each do |value|
    it "returns true when cluster_readiness_check_enabled is '#{value}'" do
      node.override['cluster']['cluster_readiness_check_enabled'] = value
      expect(cluster_readiness_check_enabled?).to be true
    end
  end

  %w(false FALSE invalid).each do |value|
    it "returns false when cluster_readiness_check_enabled is '#{value}'" do
      node.override['cluster']['cluster_readiness_check_enabled'] = value
      expect(cluster_readiness_check_enabled?).to be false
    end
  end
end

describe 'cluster_readiness_check_ignore_failure?' do
  let(:node) { Chef::Node.new }

  %w(true True TRUE).each do |value|
    expected = true
    it "returns #{expected} when cluster_readiness_check_ignore_failure is '#{value}'" do
      node.override['cluster']['cluster_readiness_check_ignore_failure'] = value
      expect(cluster_readiness_check_ignore_failure?).to be true
    end
  end

  %w(false False FALSE invalid).each do |value|
    expected = false
    it "returns #{expected} when cluster_readiness_check_ignore_failure is '#{value}'" do
      node.override['cluster']['cluster_readiness_check_ignore_failure'] = value
      expect(cluster_readiness_check_ignore_failure?).to be expected
    end
  end
end
