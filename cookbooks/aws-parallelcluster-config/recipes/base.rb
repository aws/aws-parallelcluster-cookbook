# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: base
#
# Copyright:: 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

include_recipe "aws-parallelcluster::setup_envars"
include_recipe 'aws-parallelcluster-config::openssh'

# Restore old behavior with sticky bits in Ubuntu 20 to allow root writing to files created by other users
if platform?('ubuntu') && node['platform_version'].to_i == 20
  sysctl 'fs.protected_regular' do
    value 0
  end
end

include_recipe 'aws-parallelcluster-config::nfs' unless virtualized?

service "setup-ephemeral" do
  supports restart: false
  action %i(enable start)
end

# Increase somaxconn and tcp_max_syn_backlog for large scale setting
sysctl 'net.core.somaxconn' do
  value 65_535
end

sysctl 'net.ipv4.tcp_max_syn_backlog' do
  value 65_535
end

# Amazon Time Sync
include_recipe 'aws-parallelcluster-config::chrony'

# NVIDIA services (fabric manager)
include_recipe "aws-parallelcluster-config::nvidia"

# EFA runtime configuration
include_recipe "aws-parallelcluster-config::efa" unless virtualized?

case node['cluster']['node_type']
when 'HeadNode'
  include_recipe 'aws-parallelcluster-config::head_node_base'
when 'ComputeFleet'
  include_recipe 'aws-parallelcluster-config::compute_base'
else
  raise "node_type must be HeadNode or ComputeFleet"
end

# Ensure cluster user can sudo on SSH
template '/etc/sudoers.d/99-parallelcluster-user-tty' do
  source 'base/99-parallelcluster-user-tty.erb'
  owner 'root'
  group 'root'
  mode '0600'
end

# Install parallelcluster specific supervisord config
template '/etc/parallelcluster/parallelcluster_supervisord.conf' do
  source 'base/parallelcluster_supervisord.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

# Mount EFS directory with efs_mount recipe
include_recipe 'aws-parallelcluster-config::efs_mount'

# Mount FSx directory with fsx_mount recipe
include_recipe 'aws-parallelcluster-config::fsx_mount'

# Intel Runtime Libraries
include_recipe "aws-parallelcluster-config::intel"
