# frozen_string_literal: true

# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

efa 'Configure system for EFA' do
  action :configure
end
nfs "Configure NFS" do
  action :configure
end
include_recipe 'aws-parallelcluster-environment::ephemeral_drives'
# update_fs_mapping generates the shared storage mapping file, so it must be executed before shared storage recipes
include_recipe 'aws-parallelcluster-environment::update_fs_mapping'
# Export the home dir from the head node when using ebs
include_recipe 'aws-parallelcluster-environment::export_home'

if node['cluster']['shared_storage_type'] == 'ebs'
  # Export internal use dirs from the head node
  include_recipe 'aws-parallelcluster-environment::export_internal_use_ebs'
  # Mount intel on compute and login nodes
  include_recipe 'aws-parallelcluster-environment::mount_intel_dir'
end

include_recipe 'aws-parallelcluster-environment::ebs'
include_recipe 'aws-parallelcluster-environment::raid'
include_recipe 'aws-parallelcluster-environment::efs'
include_recipe 'aws-parallelcluster-environment::fsx'
# TODO: Disable Spack until the feature is complete
# spack 'Configure Spack Packages' do
#   action :configure
# end
include_recipe 'aws-parallelcluster-environment::config_cfn_hup'
