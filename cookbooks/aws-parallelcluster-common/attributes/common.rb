# Common attributes shared between multiple cookbooks

default['cluster']['kernel_release'] = node['kernel']['release'] unless default['cluster'].key?('kernel_release')

# Base dir
default['cluster']['base_dir'] = '/opt/parallelcluster'
default['cluster']['sources_dir'] = "#{node['cluster']['base_dir']}/sources"
default['cluster']['scripts_dir'] = "#{node['cluster']['base_dir']}/scripts"
default['cluster']['license_dir'] = "#{node['cluster']['base_dir']}/licenses"
default['cluster']['configs_dir'] = "#{node['cluster']['base_dir']}/configs"
default['cluster']['shared_dir'] = "#{node['cluster']['base_dir']}/shared"

default['cluster']['head_node_home_path'] = '/home'
default['cluster']['shared_dir_compute'] = node['cluster']['shared_dir']
default['cluster']['shared_dir_head'] = node['cluster']['shared_dir']

default['cluster']['ebs_shared_dirs'] = '/shared'
default['cluster']['exported_ebs_shared_dirs'] = node['cluster']['ebs_shared_dirs']

# Python Version
default['cluster']['python-version'] = '3.9.16'
# FIXME: Python Version cfn_bootstrap_virtualenv due to a bug with cfn-hup
default['cluster']['python-version-cfn_bootstrap_virtualenv'] = '3.7.16'
# plcuster-specific pyenv system installation root
default['cluster']['system_pyenv_root'] = "#{node['cluster']['base_dir']}/pyenv"
# Virtualenv Cookbook Name
default['cluster']['cookbook_virtualenv'] = 'cookbook_virtualenv'
# Virtualenv Node Name
default['cluster']['node_virtualenv'] = 'node_virtualenv'
# Virtualenv AWSBatch Name
default['cluster']['awsbatch_virtualenv'] = 'awsbatch_virtualenv'
# Virtualenv cfn-bootstrap Name
default['cluster']['cfn_bootstrap_virtualenv'] = 'cfn_bootstrap_virtualenv'
# Cookbook Virtualenv Path
default['cluster']['cookbook_virtualenv_path'] = "#{node['cluster']['system_pyenv_root']}/versions/#{node['cluster']['python-version']}/envs/#{node['cluster']['cookbook_virtualenv']}"
# Node Virtualenv Path
default['cluster']['node_virtualenv_path'] = "#{node['cluster']['system_pyenv_root']}/versions/#{node['cluster']['python-version']}/envs/#{node['cluster']['node_virtualenv']}"
# AWSBatch Virtualenv Path
default['cluster']['awsbatch_virtualenv_path'] = "#{node['cluster']['system_pyenv_root']}/versions/#{node['cluster']['python-version']}/envs/#{node['cluster']['awsbatch_virtualenv']}"
# cfn-bootstrap Virtualenv Path
default['cluster']['cfn_bootstrap_virtualenv_path'] = "#{node['cluster']['system_pyenv_root']}/versions/#{node['cluster']['python-version-cfn_bootstrap_virtualenv']}/envs/#{node['cluster']['cfn_bootstrap_virtualenv']}"

# cfn-bootstrap
default['cluster']['cfn_bootstrap']['version'] = '2.0-24'
default['cluster']['cfn_bootstrap']['package'] = "aws-cfn-bootstrap-py3-#{node['cluster']['cfn_bootstrap']['version']}.tar.gz"

# Python packages
default['cluster']['parallelcluster-version'] = '3.7.0'
default['cluster']['parallelcluster-cookbook-version'] = '3.7.0'
default['cluster']['parallelcluster-node-version'] = '3.7.0'
default['cluster']['parallelcluster-awsbatch-cli-version'] = '1.1.0'

# NVIDIA
default['cluster']['nvidia']['enabled'] = 'no'
default['cluster']['nvidia']['driver_version'] = '470.182.03'
default['cluster']['nvidia']['cuda_version'] = '11.8'
default['cluster']['nvidia']['cuda_samples_version'] = '11.8'
default['cluster']['nvidia']['driver_url_architecture_id'] = arm_instance? ? 'aarch64' : 'x86_64'
default['cluster']['nvidia']['cuda_url_architecture_id'] = arm_instance? ? 'linux_sbsa' : 'linux'
default['cluster']['nvidia']['driver_url'] = "https://us.download.nvidia.com/tesla/#{node['cluster']['nvidia']['driver_version']}/NVIDIA-Linux-#{node['cluster']['nvidia']['driver_url_architecture_id']}-#{node['cluster']['nvidia']['driver_version']}.run"
default['cluster']['nvidia']['cuda_url'] = "https://developer.download.nvidia.com/compute/cuda/11.7.1/local_installers/cuda_11.7.1_515.65.01_#{node['cluster']['nvidia']['cuda_url_architecture_id']}.run"
default['cluster']['nvidia']['cuda_samples_url'] = "https://github.com/NVIDIA/cuda-samples/archive/refs/tags/v#{node['cluster']['nvidia']['cuda_samples_version']}.tar.gz"
