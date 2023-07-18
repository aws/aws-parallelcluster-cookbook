# Create configuration file
template "#{node['cluster']['shared_dir_login_nodes']}/login_nodes_daemon_config.json" do
  source 'slurm/login/login_nodes_daemon_config.json.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    GRACETIME_PERIOD: lazy { node['cluster']['config'].dig(:LoginNodes, :Pools, 0, :GracetimePeriod) }
  )
end

# Create on_termination_script.sh
template "#{node['cluster']['shared_dir_login_nodes']}/login_nodes_on_termination.sh" do
  source 'slurm/login/login_nodes_on_termination.sh.erb'
  owner 'root'
  group 'root'
  mode '0744'
end

# Create daemon_script.sh
template "#{node['cluster']['shared_dir_login_nodes']}/login_nodes_daemon.sh" do
  source 'slurm/login/login_nodes_daemon.sh.erb'
  owner 'root'
  group 'root'
  mode '0744'
end

# Start daemon service
execute 'start login_nodes_daemon_service' do
  command "#{node['cookbook_virtualenv_path']}/bin/supervisorctl start login_nodes_daemon_service"
end
