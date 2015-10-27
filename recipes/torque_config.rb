include_recipe 'cfncluster::base_config'
include_recipe 'cfncluster::torque_install'

# case node['cfncluster']['cfn_node_type']
case node['cfncluster']['cfn_node_type']
when 'MasterServer'
  include_recipe 'cfncluster::_master_torque_config'
when 'ComputeFleet'
  include_recipe 'cfncluster::_compute_torque_config'
else
  fail "cfn_node_type must be MasterServer or ComputeFleet"
end
