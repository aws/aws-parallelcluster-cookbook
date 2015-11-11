# Run torque.setup
bash "run-torque-setup" do
  code <<-EOH
    . /etc/profile.d/torque.sh
    ./torque.setup root
  EOH
  cwd '/opt/torque/bin'
end

# Copy pbs_server service script
remote_file "install pbs_server service" do
  path "/etc/init.d/pbs_server"
  source node['cfncluster']['torque']['pbs_server_source']
  owner 'root'
  group 'root'
  mode 0755
end

# Enable and start pbs_server service
service "pbs_server" do
  supports :restart => true
  action [ :enable, :restart ]
end

# Copy pbs_sched service script
remote_file "install pbs_sched service" do
  path "/etc/init.d/pbs_sched"
  source node['cfncluster']['torque']['pbs_sched_source']
  owner 'root'
  group 'root'
  mode 0755
end

# Enable and start pbs_sched service
service "pbs_sched" do
  supports :restart => true
  action [ :enable, :start ]
end

# Add publish_pending to cron
template '/opt/cfncluster/scripts/publish_pending' do
  source 'publish_pending.torque.erb'
  owner 'root'
  group 'root'
  mode '0744'
end

cron 'publish_pending' do
  command '/opt/cfncluster/scripts/publish_pending'
end
