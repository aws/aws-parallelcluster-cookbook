require_relative '../../../libraries/helpers'
require 'spec_helper'

describe 'cfnhup_enabled?' do
  let(:node) { Chef::Node.new }

  context 'when node type is HeadNode' do
    before { node.override['cluster']['node_type'] = 'HeadNode' }

    it 'returns true regardless of in_place_update_on_fleet_enabled setting' do
      node.override['cluster']['in_place_update_on_fleet_enabled'] = 'false'
      expect(cfnhup_enabled?).to be true
    end
  end

  %w(ComputeFleet LoginNode).each do |node_type|
    context "when node type is #{node_type}" do
      before { node.override['cluster']['node_type'] = node_type }

      it 'returns true when in_place_update_on_fleet_enabled is true' do
        node.override['cluster']['in_place_update_on_fleet_enabled'] = 'true'
        expect(cfnhup_enabled?).to be true
      end

      it 'returns false when in_place_update_on_fleet_enabled is false' do
        node.override['cluster']['in_place_update_on_fleet_enabled'] = 'false'
        expect(cfnhup_enabled?).to be false
      end
    end
  end
end

describe 'cluster_readiness_check_on_update_enabled?' do
  let(:node) { Chef::Node.new }

  [true, false].each do |cluster_readiness_check_enabled|
    [true, false].each do |in_place_update_on_fleet_enabled|
      expected = cluster_readiness_check_enabled && in_place_update_on_fleet_enabled
      it "returns #{expected} when cluster_readiness_check_enabled is #{cluster_readiness_check_enabled} and in_place_update_on_fleet_enabled is #{in_place_update_on_fleet_enabled}" do
        node.override['cluster']['cluster_readiness_check_enabled'] = cluster_readiness_check_enabled.to_s
        node.override['cluster']['in_place_update_on_fleet_enabled'] = in_place_update_on_fleet_enabled.to_s
        expect(cluster_readiness_check_on_update_enabled?).to be expected
      end
    end
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
