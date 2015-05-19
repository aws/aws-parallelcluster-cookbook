include_recipe 'cfncluster::base_install'

# case node['cfncluster']['cfn_node_type']
case node['cfncluster']['cfn_node_type']
when 'MasterServer'
  include_recipe 'cfncluster::_master_base_config'
when 'ComputeFleet'
  include_recipe 'cfncluster::_compute_base_config'
else
  fail "cfn_node_type must be MasterServer or ComputeFleet"
end

# Ensure cluster user can sudo on SSH
template '/etc/sudoers.d/99-cfncluster-user-tty' do
  source '99-cfncluster-user-tty.erb'
  owner 'root'
  group 'root'
  mode '0600'
end

# Install cfncluster specific supervisord config
template '/etc/cfncluster/cfncluster_supervisord.conf' do
  source 'cfncluster_supervisord.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

# Restart supervisord
service "supervisord" do
  supports :restart => true
  action [ :enable, :start ]
end
