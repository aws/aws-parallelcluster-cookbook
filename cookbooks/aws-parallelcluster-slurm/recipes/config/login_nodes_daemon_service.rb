GRACETIME_PERIOD = lazy { node['cluster']['config'].dig(:LoginNodes, :Pools, 0, :GracetimePeriod) }

# Create configuration file
template "#{node['cluster']['shared_dir_login_nodes']}/login_nodes_daemon_config.json" do
  source 'slurm/login/login_nodes_daemon_config.json.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    GRACETIME_PERIOD: GRACETIME_PERIOD,
  )
end

# Create on_termination_script.sh
template "#{node['cluster']['shared_dir_login_nodes']}/login_nodes_on_termination_script.sh" do
  source 'slurm/login/login_nodes_on_termination.sh.erb'
  owner 'root'
  group 'root'
  mode '0744'
end

# Create daemon_script.sh
template "#{node['cluster']['shared_dir_login_nodes']}/login_nodes_daemon_script.sh" do
  source 'slurm/login/login_nodes_daemon.sh.erb'
  owner 'root'
  group 'root'
  mode '0744'
end

# Create supervisord configuration for the daemon
file "/etc/supervisor/conf.d/login_nodes_daemon_service.conf" do
  content <<-EOF
[program:login_nodes_daemon_service]
command=bash #{node['cluster']['shared_dir_login_nodes']}/login_nodes_daemon_script.sh
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
  EOF
end

# Update supervisor configuration
execute 'supervisorctl reread' do
  command 'supervisorctl reread'
end

# Start daemon service
execute 'supervisorctl start login_nodes_daemon_service' do
  command 'supervisorctl start login_nodes_daemon_service'
end
