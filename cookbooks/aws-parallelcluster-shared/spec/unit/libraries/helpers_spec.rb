require_relative '../../../libraries/helpers'
require 'spec_helper'

describe 'cluster_readiness_check_on_update_enabled?' do
  let(:node) { Chef::Node.new }

  [true, false].each do |cluster_readiness_check_enabled|
    it "returns #{cluster_readiness_check_enabled} when cluster_readiness_check_enabled is #{cluster_readiness_check_enabled}" do
      node.override['cluster']['update']['cluster_readiness_check_enabled'] = cluster_readiness_check_enabled.to_s
      expect(cluster_readiness_check_on_update_enabled?).to be cluster_readiness_check_enabled
    end
  end
end
