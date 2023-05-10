# Common attributes shared between multiple cookbooks

default['cluster']['kernel_release'] = node['kernel']['release'] unless default['cluster'].key?('kernel_release')

# Base dir

default['cluster']['head_node_home_path'] = '/home'
default['cluster']['shared_dir_compute'] = node['cluster']['shared_dir']
default['cluster']['shared_dir_head'] = node['cluster']['shared_dir']

default['cluster']['ebs_shared_dirs'] = '/shared'
default['cluster']['exported_ebs_shared_dirs'] = node['cluster']['ebs_shared_dirs']

# Virtualenv Node Name
default['cluster']['node_virtualenv'] = 'node_virtualenv'
# Node Virtualenv Path
default['cluster']['node_virtualenv_path'] = "#{node['cluster']['system_pyenv_root']}/versions/#{node['cluster']['python-version']}/envs/#{node['cluster']['node_virtualenv']}"

# Python packages
default['cluster']['parallelcluster-version'] = '3.7.0'
default['cluster']['parallelcluster-cookbook-version'] = '3.7.0'
default['cluster']['parallelcluster-node-version'] = '3.7.0'
default['cluster']['parallelcluster-awsbatch-cli-version'] = '1.1.0'

# NVIDIA
default['cluster']['nvidia']['enabled'] = 'no'
default['cluster']['nvidia']['driver_version'] = '470.182.03'
# Cuda installer from https://developer.nvidia.com/cuda-toolkit-archive
# Cuda installer naming: cuda_11.8.0_520.61.05_linux
default['cluster']['nvidia']['cuda']['version'] = '11.8'
default['cluster']['nvidia']['cuda']['patch'] = '0'
default['cluster']['nvidia']['cuda']['complete_version'] = "#{node['cluster']['nvidia']['cuda']['version']}.#{node['cluster']['nvidia']['cuda']['patch']}"
default['cluster']['nvidia']['cuda']['version_suffix'] = '520.61.05'
default['cluster']['nvidia']['cuda_samples_version'] = '11.8'
default['cluster']['nvidia']['driver_url_architecture_id'] = arm_instance? ? 'aarch64' : 'x86_64'
default['cluster']['nvidia']['cuda']['url_architecture_id'] = arm_instance? ? 'linux_sbsa' : 'linux'
default['cluster']['nvidia']['driver_url'] = "https://us.download.nvidia.com/tesla/#{node['cluster']['nvidia']['driver_version']}/NVIDIA-Linux-#{node['cluster']['nvidia']['driver_url_architecture_id']}-#{node['cluster']['nvidia']['driver_version']}.run"
default['cluster']['nvidia']['cuda']['url'] = "https://developer.download.nvidia.com/compute/cuda/#{node['cluster']['nvidia']['cuda']['complete_version']}/local_installers/cuda_#{node['cluster']['nvidia']['cuda']['complete_version']}_#{node['cluster']['nvidia']['cuda']['version_suffix']}_#{node['cluster']['nvidia']['cuda']['url_architecture_id']}.run"
default['cluster']['nvidia']['cuda_samples_url'] = "https://github.com/NVIDIA/cuda-samples/archive/refs/tags/v#{node['cluster']['nvidia']['cuda_samples_version']}.tar.gz"

# EFA
default['cluster']['efa']['installer_version'] = '1.22.1'
default['cluster']['efa']['sha256'] = 'f90f3d5f59c031b9a964466b5401e86fd0429272408f6c207c3f9048254e9665'
default['cluster']['efa']['unsupported_aarch64_oses'] = %w(centos7)

# CloudWatch Agent
default['cluster']['cloudwatch']['public_key_url'] = "https://s3.amazonaws.com/amazoncloudwatch-agent/assets/amazon-cloudwatch-agent.gpg"
default['cluster']['cloudwatch']['public_key_local_path'] = "#{node['cluster']['sources_dir']}/amazon-cloudwatch-agent.gpg"

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
default['cluster']['head_node_imds_allowed_users'] = ['root', lazy { node['cluster']['cluster_admin_user'] }, lazy { node['cluster']['cluster_user'] }]
default['cluster']['head_node_imds_allowed_users'].append('dcv') if node['cluster']['dcv_enabled'] == 'head_node' && platform_supports_dcv?
default['cluster']['head_node_imds_allowed_users'].append(lazy { node['cluster']['scheduler_plugin']['user'] }) if node['cluster']['scheduler'] == 'plugin'

# Default NFS mount options
default['cluster']['nfs']['hard_mount_options'] = 'hard,_netdev,noatime'

default['cluster']['computefleet_status_path'] = "#{node['cluster']['shared_dir']}/computefleet-status.json"
default['cluster']['head_node_private_ip'] = nil
