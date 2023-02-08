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

include_recipe "aws-parallelcluster-common::setup_envars"
include_recipe 'aws-parallelcluster-config::openssh'

sticky_bits "setup sticky bits"

include_recipe 'aws-parallelcluster-config::nfs' unless virtualized?

# Mount the ephemeral drive unless there is a mountpoint collision with shared drives
shared_dir_array = node['cluster']['ebs_shared_dirs'].split(',') + \
                   node['cluster']['efs_shared_dirs'].split(',') + \
                   node['cluster']['fsx_shared_dirs'].split(',') + \
                   [ node['cluster']['raid_shared_dir'] ]
unless shared_dir_array.include? node['cluster']['ephemeral_dir']
  service "setup-ephemeral" do
    supports restart: false
    action :enable
  end

  # Execution timeout 3600 seconds
  unless virtualized?
    execute "Setup of ephemeral drives" do
      user "root"
      command "/usr/local/sbin/setup-ephemeral-drives.sh"
    end
  end
end

include_recipe 'aws-parallelcluster-config::networking'

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

# Mount EFS, FSx
include_recipe "aws-parallelcluster-config::fs_mount"

# Intel Runtime Libraries
include_recipe "aws-parallelcluster-config::intel"
