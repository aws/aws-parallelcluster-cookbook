# Ubuntu 22 default attributes for aws-parallelcluster-install

return unless platform?('ubuntu') && node['platform_version'] == "22.04"

default['nfs']['service_provider']['idmap'] = Chef::Provider::Service::Systemd
default['nfs']['service_provider']['portmap'] = Chef::Provider::Service::Systemd
default['nfs']['service_provider']['lock'] = Chef::Provider::Service::Systemd
default['nfs']['service']['lock'] = 'rpc-statd'
default['nfs']['service']['idmap'] = 'nfs-idmapd'
