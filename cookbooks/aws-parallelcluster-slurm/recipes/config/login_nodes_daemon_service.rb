require 'yaml'
config = YAML.safe_load(File.read(node['cluster']['cluster_config_path']))
GRACETIME_PERIOD = config["LoginNodes"]["Pools"][0]["GRACETIME_PERIOD"]

# Create configuration file
template "#{node['cluster']['shared_dir']}/login_nodes_daemon_config.json" do
  source 'login_nodes_daemon_service/login_nodes_daemon_config.json.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    {
      GRACETIME_PERIOD: GRACETIME_PERIOD,
    }
  )
end

# Create on_termination_script.sh
template "#{node['cluster']['shared_dir']}/login_nodes_on_termination_script.sh" do
  source 'login_nodes_daemon_service/login_nodes_on_termination_script.sh.erb'
  owner 'root'
  group 'root'
  mode '0755'
end

# Create daemon_script.sh
template "#{node['cluster']['shared_dir']}/login_nodes_daemon_script.sh" do
  source 'login_nodes_daemon_service/login_nodes_daemon_script.sh.erb'
  owner 'root'
  group 'root'
  mode '0755'
end

# Create supervisord configuration for the daemon
file "/etc/supervisor/conf.d/login_nodes_daemon_service.conf" do
  content <<-EOF
[program:login_nodes_daemon_service]
command=bash #{node['cluster']['shared_dir']}/login_nodes_daemon_script.sh #{GRACETIME_PERIOD}
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
