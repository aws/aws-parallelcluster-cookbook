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
  include_recipe 'aws-parallelcluster-config::head_node_base'
when 'ComputeFleet'
  include_recipe 'aws-parallelcluster-environment::compute_base'
else
  raise "node_type must be HeadNode or ComputeFleet"
end

include_recipe "aws-parallelcluster-config::sudo"

# Mount EFS, FSx
include_recipe "aws-parallelcluster-environment::fs_mount"

# Intel Runtime Libraries
intel_hpc 'Configure Intel HPC' do
  action :configure
end
