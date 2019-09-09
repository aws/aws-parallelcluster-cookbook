#
# Cookbook Name:: aws-parallelcluster
# Recipe:: base_config
#
# Copyright 2013-2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

include_recipe 'aws-parallelcluster::base_install'

# Setup hostnames to be short
node.default['set_fqdn'] = node['ec2']['local_hostname']
node.default['hostname_cookbook']['hostsfile_ip'] = node['ec2']['local_ipv4']
include_recipe 'hostname::default'
ignore_failure 'service[network]' if node['platform_family'] == 'rhel'

# Setup ephemeral drives
execute 'setup ephemeral' do
  command '/usr/local/sbin/setup-ephemeral-drives.sh'
  creates '/scratch'
end

# case node['cfncluster']['cfn_node_type']
case node['cfncluster']['cfn_node_type']
when 'MasterServer'
  include_recipe 'aws-parallelcluster::_master_base_config'
when 'ComputeFleet'
  include_recipe 'aws-parallelcluster::_compute_base_config'
else
  raise "cfn_node_type must be MasterServer or ComputeFleet"
end

# Ensure cluster user can sudo on SSH
template '/etc/sudoers.d/99-parallelcluster-user-tty' do
  source '99-parallelcluster-user-tty.erb'
  owner 'root'
  group 'root'
  mode '0600'
end

# Install parallelcluster specific supervisord config
template '/etc/parallelcluster/parallelcluster_supervisord.conf' do
  source 'parallelcluster_supervisord.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

# Mount EFS directory with efs_mount recipe
include_recipe 'aws-parallelcluster::efs_mount'

# Mount FSx directory with fsx_mount recipe
include_recipe 'aws-parallelcluster::fsx_mount'
