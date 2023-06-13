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
include_recipe "aws-parallelcluster-platform::sudo_config"
include_recipe 'aws-parallelcluster-platform::cluster_user'
include_recipe 'aws-parallelcluster-platform::networking'
include_recipe "aws-parallelcluster-platform::nvidia_config"
sticky_bits "setup sticky bits"
chrony 'enable Amazon Time Sync' do
  action :enable
end
include_recipe 'aws-parallelcluster-platform::dcv'
intel_hpc 'Configure Intel HPC' do
  action :configure
end

efa 'Configure system for EFA' do
  action :configure
end

# Configure file system
nfs "Configure NFS" do
  action :configure
end
include_recipe 'aws-parallelcluster-environment::ephemeral_drives'
# fs_update generates the shared storages mapping file so must be executed before shared storages recipes
include_recipe 'aws-parallelcluster-environment::fs_update'
include_recipe 'aws-parallelcluster-environment::shared_storages'
include_recipe 'aws-parallelcluster-environment::ebs'
include_recipe 'aws-parallelcluster-environment::raid'
include_recipe "aws-parallelcluster-environment::fs_mount"

fetch_config 'Fetch and load cluster configs'

include_recipe 'aws-parallelcluster-computefleet::fleet_status'
include_recipe 'aws-parallelcluster-slurm::config'
include_recipe 'aws-parallelcluster-scheduler-plugin::config'
include_recipe 'aws-parallelcluster-awsbatch::config'

include_recipe "aws-parallelcluster-platform::log_rotation"
