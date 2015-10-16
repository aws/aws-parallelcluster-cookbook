
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

execute "openlava.setup" do
  environment ( { "LSF_ENVDIR" => "/opt/openlava/etc" } )
  cwd '/opt/openlava/etc'
  command 'sh ./openlava.setup'
  not_if { ::File.exists?('/etc/init.d/openlava') }
end

service "openlava" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end
