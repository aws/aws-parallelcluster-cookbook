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

return if on_docker?

include_recipe "aws-parallelcluster-environment::update_fs_mapping"
include_recipe "aws-parallelcluster-environment::backup_internal_use_shared_data"

efs_shared_dir_array = node['cluster']['efs_shared_dirs'].split(',')
efs_fs_id_array = node['cluster']['efs_fs_ids'].split(',')
efs_encryption_in_transit_array = node['cluster']['efs_encryption_in_transits'].split(',')
efs_iam_authorization_array = node['cluster']['efs_iam_authorizations'].split(',')

initial_shared_dir_array = []
initial_efs_fs_id_array = []
initial_efs_encryption_array = []
initial_efs_iam_array = []

# Identify the initial filesystem and store their data in arrays for the EFS resource
efs_shared_dir_array.each_with_index do |dir, index|
  next unless dir == node['cluster']['internal_initial_shared_dir']
  initial_shared_dir_array.push(dir)
  initial_efs_fs_id_array.push(efs_fs_id_array[index])
  initial_efs_encryption_array.push(efs_encryption_in_transit_array[index])
  initial_efs_iam_array.push(efs_iam_authorization_array[index])
end

if node['cluster']['node_type'] == 'HeadNode'
  # Mount the initial internal use EFS
  efs "mount initial internal use efs" do
    shared_dir_array initial_shared_dir_array
    efs_fs_id_array initial_efs_fs_id_array
    efs_encryption_in_transit_array initial_efs_encryption_array
    efs_iam_authorization_array initial_efs_iam_array
    action :mount
    not_if { initial_shared_dir_array.empty? }
  end

  # Add the mount points for shared dirs
  node['cluster']['internal_shared_dirs'].each do |dir|
    directory "#{node['cluster']['internal_initial_shared_dir']}#{dir}" do
      user 'root'
      group 'root'
      mode '0755'
      action :create
      recursive true
    end
  end unless initial_shared_dir_array.empty?

  # Unmount the root of the EFS after creating the shared directories
  # TODO this doesn't seem to unmount the EFS
  efs "unmount internal efs" do
    shared_dir_array(lazy { initial_shared_dir_array })
    efs_fs_id_array(lazy { initial_efs_fs_id_array })
    action :unmount
    not_if { initial_shared_dir_array.empty? }
  end
end

# Mount the shared dirs, there should only be one initial shared dir array
internal_shared_dir_array = []
internal_efs_fs_id_array = []
internal_efs_encryption_array = []
internal_efs_iam_array = []
internal_efs_mount_point_array = []
node['cluster']['internal_shared_dirs'].each do |dir|
  # Don't mount the login nodes shared dir to compute nodes
  next if node['cluster']['node_type'] == 'ComputeFleet' && dir == node['cluster']['shared_dir_login_nodes']
  internal_shared_dir_array.push(dir)
  internal_efs_fs_id_array.push(initial_efs_fs_id_array[0])
  internal_efs_encryption_array.push(initial_efs_encryption_array[0])
  internal_efs_iam_array.push(initial_efs_iam_array[0])
  internal_efs_mount_point_array.push(dir)
end unless initial_shared_dir_array.empty?

efs "mount internal shared efs" do
  shared_dir_array internal_shared_dir_array
  efs_fs_id_array internal_efs_fs_id_array
  efs_encryption_in_transit_array internal_efs_encryption_array
  efs_iam_authorization_array internal_efs_iam_array
  efs_mount_point_array internal_efs_mount_point_array
  action :mount
  not_if { internal_shared_dir_array.empty? }
end

include_recipe "aws-parallelcluster-environment::restore_internal_use_shared_data"
