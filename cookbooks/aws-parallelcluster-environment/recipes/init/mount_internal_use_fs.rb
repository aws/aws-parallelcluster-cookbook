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
efs_shared_dir_array = node['cluster']['efs_shared_dirs'].split(',')
efs_fs_id_array = node['cluster']['efs_fs_ids'].split(',')
efs_encryption_in_transit_array = node['cluster']['efs_encryption_in_transits'].split(',')
efs_iam_authorization_array = node['cluster']['efs_iam_authorizations'].split(',')

internal_shared_dir_array = []
internal_efs_fs_id_array = []
internal_efs_encryption_array = []
internal_efs_iam_array = []

# Identify the internal use filesystems and store their data in arrays for the EFS resource
efs_shared_dir_array.each_with_index do |dir, index|
  next unless node['cluster']['internal_shared_dirs'].include?(dir)
  # Don't mount the login nodes shared dir to compute nodes
  next if node['cluster']['node_type'] == 'ComputeFleet' && dir == node['cluster']['shared_dir_login_nodes']
  internal_shared_dir_array.push(dir)
  internal_efs_fs_id_array.push(efs_fs_id_array[index])
  internal_efs_encryption_array.push(efs_encryption_in_transit_array[index])
  internal_efs_iam_array.push(efs_iam_authorization_array[index])
end

# Mount EFS directories with the efs resource
efs "mount internal use efs" do
  shared_dir_array internal_shared_dir_array
  efs_fs_id_array internal_efs_fs_id_array
  efs_encryption_in_transit_array internal_efs_encryption_array
  efs_iam_authorization_array internal_efs_iam_array
  action :mount
  not_if { internal_shared_dir_array.empty? }
end

# TODO: replace home as NFS with shared /home
case node['cluster']['node_type']
when 'ComputeFleet', 'LoginNode'
  include_recipe 'aws-parallelcluster-environment::mount_home'
when 'HeadNode'
  Chef::Log.info("Nothing to mount in the HeadNode")
else
  raise "node_type must be HeadNode, LoginNode or ComputeFleet"
end
