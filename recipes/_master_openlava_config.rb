
# Openlava config files
template '/opt/openlava/etc/lsf.conf' do
  source 'lsf.conf.erb'
  owner 'openlava'
  group 'openlava'
  mode '0644'
end

template '/opt/openlava/etc/lsf.cluster.openlava' do
  source 'lsf.cluster.openlava.erb'
  owner 'openlava'
  group 'openlava'
  mode '0644'
end

template '/opt/openlava/etc/lsb.hosts' do
  source 'lsb.hosts.erb'
  owner 'openlava'
  group 'openlava'
  mode '0644'
end

template '/opt/openlava/etc/lsf.shared' do
  source 'lsf.shared.erb'
  owner 'openlava'
  group 'openlava'
  mode '0644'
end

template '/opt/cfncluster/scripts/publish_pending' do
  source 'publish_pending.openlava.erb'
  owner 'root'
  group 'root'
  mode '0744'
end

cookbook_file 'openlava-init' do
  path '/etc/init.d/openlava'
  user 'root'
  group 'root'
  mode '0755'
end

service "openlava" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

execute "badmin hclose" do
  environment ( { "LSF_ENVDIR" => "/opt/openlava/etc" } )
  command '/opt/openlava/bin/badmin hclose'
end

cron 'publish_pending' do
  command '/opt/cfncluster/scripts/publish_pending'
end
