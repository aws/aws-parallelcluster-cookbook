# frozen_string_literal: true

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

# Restart sshd.service to make sure the service is running
# This is a workaround for Centos 8 where the sshd.service fails at first start since it does not properly
# wait for cloud-init.service to start. There is something wrong in Centos 8 systemd dependency chain.
if node['platform'] == 'centos' && node['platform_version'].to_i == 8
  service "sshd" do
    supports restart: true
    action %i[enable restart]
  end
end

# Restore old behavior with sticky bits in Ubuntu 20 to allow root writing to files created by other users
# This is especially needed for sge install recipes
if node['platform'] == 'ubuntu' && node['platform_version'].to_i == 20
  sysctl 'fs.protected_regular' do
    value 0
  end
end

include_recipe 'aws-parallelcluster::nfs_config'

# Setup ephemeral drives
execute 'setup ephemeral' do
  command '/usr/local/sbin/setup-ephemeral-drives.sh'
  creates '/scratch'
end

# Increase somaxconn and tcp_max_syn_backlog for large scale setting
sysctl 'net.core.somaxconn' do
  value 65_535
end

sysctl 'net.ipv4.tcp_max_syn_backlog' do
  value 65_535
end

# Amazon Time Sync
include_recipe 'aws-parallelcluster::chrony_config'

# NVIDIA services (fabric manager)
include_recipe "aws-parallelcluster::nvidia_config"

# EFA runtime configuration
include_recipe "aws-parallelcluster::efa_config"

case node['cfncluster']['cfn_node_type']
when 'MasterServer'
  include_recipe 'aws-parallelcluster::head_node_base_config'
when 'ComputeFleet'
  include_recipe 'aws-parallelcluster::compute_base_config'
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

# Intel Runtime Libraries
include_recipe "aws-parallelcluster::intel_install"
