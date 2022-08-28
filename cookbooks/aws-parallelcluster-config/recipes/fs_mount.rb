# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: fs_mount
#
# Copyright:: 2013-2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Mount EFS directory with mount_efs resource
mount_efs "efs" do
  shared_dir_array node['cluster']['efs_shared_dirs'].split(',')
  vol_array node['cluster']['efs_fs_ids'].split(',')
end

# Mount FSx directory with mount_fsx resource
mount_fsx "fsx" do
  fsx_fs_id_array node['cluster']['fsx_fs_ids'].split(',')
  fsx_fs_type_array node['cluster']['fsx_fs_types'].split(',')
  fsx_shared_dir_array node['cluster']['fsx_shared_dirs'].split(',')
  fsx_dns_name_array node['cluster']['fsx_dns_names'].split(',')
  fsx_mount_name_array node['cluster']['fsx_mount_names'].split(',')
  fsx_volume_junction_path_array node['cluster']['fsx_volume_junction_paths'].split(',')
end
