# pbs_mom config
template '/var/spool/torque/mom_priv/config' do
  source 'torque.config.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

# Copy pbs_mom service script
remote_file "install pbs_mom service" do
  path "/etc/init.d/pbs_mom"
  source "file:///opt/torque/contrib/init.d/pbs_mom"
  owner 'root'
  group 'root'
  mode 0755
end

# Enable and start pbs_mom service
service "pbs_mom" do
  supports :restart => true
  action [ :enable, :restart ]
end
