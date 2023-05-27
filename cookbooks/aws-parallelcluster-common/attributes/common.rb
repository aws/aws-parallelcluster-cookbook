# Common attributes shared between multiple cookbooks

default['cluster']['kernel_release'] = node['kernel']['release'] unless default['cluster'].key?('kernel_release')

# Base dir

default['cluster']['head_node_home_path'] = '/home'
default['cluster']['shared_dir_compute'] = node['cluster']['shared_dir']
default['cluster']['shared_dir_head'] = node['cluster']['shared_dir']

default['cluster']['ebs_shared_dirs'] = '/shared'
default['cluster']['exported_ebs_shared_dirs'] = node['cluster']['ebs_shared_dirs']

# NVIDIA
default['cluster']['nvidia']['enabled'] = 'no'
default['cluster']['nvidia']['driver_version'] = '470.182.03'
default['cluster']['nvidia']['driver_url_architecture_id'] = arm_instance? ? 'aarch64' : 'x86_64'
default['cluster']['nvidia']['driver_url'] = "https://us.download.nvidia.com/tesla/#{node['cluster']['nvidia']['driver_version']}/NVIDIA-Linux-#{node['cluster']['nvidia']['driver_url_architecture_id']}-#{node['cluster']['nvidia']['driver_version']}.run"

# NICE DCV
default['cluster']['dcv_port'] = 8443
default['cluster']['dcv']['installed'] = 'yes'
default['cluster']['dcv']['version'] = '2023.0-15022'
if arm_instance?
  default['cluster']['dcv']['supported_os'] = %w(centos7 ubuntu18 amazon2 redhat8)
  default['cluster']['dcv']['url_architecture_id'] = 'aarch64'
else
  default['cluster']['dcv']['supported_os'] = %w(centos7 ubuntu18 ubuntu20 amazon2 redhat8)
  default['cluster']['dcv']['url_architecture_id'] = 'x86_64'
end
default['cluster']['dcv']['server']['version'] = '2023.0.15022-1'
default['cluster']['dcv']['xdcv']['version'] = '2023.0.547-1'
default['cluster']['dcv']['gl']['version'] = '2023.0.1027-1'
default['cluster']['dcv']['web_viewer']['version'] = '2023.0.15022-1'
# DCV external authenticator configuration
default['cluster']['dcv']['authenticator']['user'] = "dcvextauth"
default['cluster']['dcv']['authenticator']['user_id'] = node['cluster']['reserved_base_uid'] + 3
default['cluster']['dcv']['authenticator']['group'] = node['cluster']['dcv']['authenticator']['user']
default['cluster']['dcv']['authenticator']['group_id'] = node['cluster']['dcv']['authenticator']['user_id']
default['cluster']['dcv']['authenticator']['user_home'] = "/home/#{node['cluster']['dcv']['authenticator']['user']}"
default['cluster']['dcv']['authenticator']['certificate'] = "/etc/parallelcluster/ext-auth-certificate.pem"
default['cluster']['dcv']['authenticator']['private_key'] = "/etc/parallelcluster/ext-auth-private-key.pem"
default['cluster']['dcv']['authenticator']['virtualenv'] = "dcv_authenticator_virtualenv"
default['cluster']['dcv']['authenticator']['virtualenv_path'] = [
  node['cluster']['system_pyenv_root'],
  'versions',
  node['cluster']['python-version'],
  'envs',
  node['cluster']['dcv']['authenticator']['virtualenv'],
].join('/')

default['conditions']['dcv_supported'] = platform_supports_dcv?

# IMDS
default['cluster']['head_node_imds_secured'] = 'true'
default['cluster']['head_node_imds_allowed_users'] = ['root', node['cluster']['cluster_admin_user'], node['cluster']['cluster_user'] ]
default['cluster']['head_node_imds_allowed_users'].append('dcv') if node['cluster']['dcv_enabled'] == 'head_node' && platform_supports_dcv?
default['cluster']['head_node_imds_allowed_users'].append(lazy { node['cluster']['scheduler_plugin']['user'] }) if node['cluster']['scheduler'] == 'plugin'

# Default NFS mount options
default['cluster']['nfs']['hard_mount_options'] = 'hard,_netdev,noatime'

default['cluster']['computefleet_status_path'] = "#{node['cluster']['shared_dir']}/computefleet-status.json"
default['cluster']['head_node_private_ip'] = nil
