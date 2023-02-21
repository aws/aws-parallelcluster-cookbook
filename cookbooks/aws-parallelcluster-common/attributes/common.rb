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

default['cluster']['exported_raid_shared_dir'] = node['cluster']['raid_shared_dir']
default['cluster']['exported_ebs_shared_dirs'] = node['cluster']['ebs_shared_dirs']
default['cluster']['exported_intel_dir'] = '/opt/intel'

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
default['cluster']['cfn_bootstrap']['version'] = '2.0-10'
default['cluster']['cfn_bootstrap']['package'] = "aws-cfn-bootstrap-py3-#{node['cluster']['cfn_bootstrap']['version']}.tar.gz"

# Python packages
default['cluster']['parallelcluster-version'] = '3.6.0'
default['cluster']['parallelcluster-cookbook-version'] = '3.6.0'
default['cluster']['parallelcluster-node-version'] = '3.6.0'
default['cluster']['parallelcluster-awsbatch-cli-version'] = '1.1.0'

# EFA
default['cluster']['efa']['installer_version'] = '1.21.0'
default['cluster']['efa']['unsupported_aarch64_oses'] = %w(centos7)
