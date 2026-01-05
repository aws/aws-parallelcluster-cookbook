require_relative '../../../libraries/helpers'
require 'spec_helper'

describe 'cluster_readiness_check_on_update_enabled?' do
  let(:node) { Chef::Node.new }

  [true, false].each do |in_place_update_on_fleet_enabled|
    it "returns #{in_place_update_on_fleet_enabled} when in_place_update_on_fleet_enabled is #{in_place_update_on_fleet_enabled}" do
      node.override['cluster']['in_place_update_on_fleet_enabled'] = in_place_update_on_fleet_enabled.to_s
      expect(cluster_readiness_check_on_update_enabled?).to be in_place_update_on_fleet_enabled
    end
  end
end
