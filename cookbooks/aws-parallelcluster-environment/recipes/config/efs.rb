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

cx_shared_dir_array = []
cx_efs_fs_id_array = []
cx_efs_encryption_array = []
cx_efs_iam_array = []

# Identify the customer use filesystems and store their data in arrays for the EFS resource
efs_shared_dir_array.each_with_index do |dir, index|
  next if node['cluster']['internal_shared_dirs'].include?(dir)
  cx_shared_dir_array.push(dir)
  cx_efs_fs_id_array.push(efs_fs_id_array[index])
  cx_efs_encryption_array.push(efs_encryption_in_transit_array[index])
  cx_efs_iam_array.push(efs_iam_authorization_array[index])
end

# Mount EFS directories with the efs resource
efs "mount efs" do
  shared_dir_array cx_shared_dir_array
  efs_fs_id_array cx_efs_fs_id_array
  efs_encryption_in_transit_array cx_efs_encryption_array
  efs_iam_authorization_array cx_efs_iam_array
  action :mount
  not_if { cx_shared_dir_array.empty? }
end
