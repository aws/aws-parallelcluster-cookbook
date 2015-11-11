include_recipe 'cfncluster::base_config'
include_recipe 'cfncluster::torque_install'

# Update ld.conf
append_if_no_line "add torque libs to ld.so.conf" do
  path "/etc/ld.so.conf.d/torque.conf"
  line "/opt/torque/lib"
  notifies :run, 'execute[run-ldconfig]', :immediately
end

# Run ldconfig
execute "run-ldconfig" do
  command 'ldconfig'
end

# Set toruqe server_name
template '/var/spool/torque/server_name' do
  source 'torque.server_name.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

# Install trqauthd service
remote_file "install trqauthd service" do
  path "/etc/init.d/trqauthd"
  source node['cfncluster']['torque']['trqauthd_source']
  owner 'root'
  group 'root'
  mode 0755
end

# Enable and start trqauthd service
service "trqauthd" do
  supports :restart => true
  action [ :enable, :start ]
end

cookbook_file "/etc/profile.d/torque.sh" do
  source 'torque.sh'
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

# case node['cfncluster']['cfn_node_type']
case node['cfncluster']['cfn_node_type']
when 'MasterServer'
  include_recipe 'cfncluster::_master_torque_config'
when 'ComputeFleet'
  include_recipe 'cfncluster::_compute_torque_config'
else
  fail "cfn_node_type must be MasterServer or ComputeFleet"
end
