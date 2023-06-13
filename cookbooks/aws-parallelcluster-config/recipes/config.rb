# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-config
# Recipe:: config
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

include_recipe "aws-parallelcluster-platform::enable_chef_error_handler"

include_recipe "aws-parallelcluster-shared::setup_envars"
include_recipe 'aws-parallelcluster-platform::openssh'

sticky_bits "setup sticky bits"

nfs "Configure NFS" do
  action :configure
end

include_recipe 'aws-parallelcluster-environment::ephemeral_drives'

include_recipe 'aws-parallelcluster-platform::networking'

# Amazon Time Sync
chrony 'enable chrony' do
  action :enable
end

# Configure Nvidia driver
include_recipe "aws-parallelcluster-platform::nvidia_config"

# EFA runtime configuration
efa 'Configure system for EFA' do
  action :configure
end

case node['cluster']['node_type']
when 'HeadNode'
  include_recipe 'aws-parallelcluster-platform::cluster_user'

  # generate the shared storages mapping file
  include_recipe 'aws-parallelcluster-environment::fs_update'

  include_recipe 'aws-parallelcluster-environment::ebs'
  include_recipe 'aws-parallelcluster-environment::shared_storages'
  include_recipe 'aws-parallelcluster-environment::raid'

  include_recipe 'aws-parallelcluster-platform::dcv'

  include_recipe 'aws-parallelcluster-computefleet::head_node_fleet_status'

when 'ComputeFleet'
  include_recipe 'aws-parallelcluster-platform::cluster_user'

  include_recipe 'aws-parallelcluster-environment::ebs'
  include_recipe 'aws-parallelcluster-environment::shared_storages'
  include_recipe 'aws-parallelcluster-environment::raid'
else
  raise "node_type must be HeadNode or ComputeFleet"
end

include_recipe "aws-parallelcluster-platform::sudo_config"

# Mount EFS, FSx
include_recipe "aws-parallelcluster-environment::fs_mount"

# Intel Runtime Libraries
intel_hpc 'Configure Intel HPC' do
  action :configure
end

fetch_config 'Fetch and load cluster configs'

include_recipe 'aws-parallelcluster-slurm::config' if node['cluster']['scheduler'] == 'slurm'
include_recipe 'aws-parallelcluster-scheduler-plugin::config' if node['cluster']['scheduler'] == 'plugin'
include_recipe 'aws-parallelcluster-awsbatch::config' if node['cluster']['scheduler'] == 'awsbatch'

include_recipe "aws-parallelcluster-platform::log_rotation"
