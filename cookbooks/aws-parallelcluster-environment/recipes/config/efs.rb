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
shared_dir_array = node['cluster']['efs_shared_dirs'].split(',')
id_array = node['cluster']['efs_fs_ids'].split(',')
encryption_array = node['cluster']['efs_encryption_in_transits'].split(',')
iam_array = node['cluster']['efs_iam_authorizations'].split(',')
access_point_id_array = node['cluster']['efs_access_point_ids'].split(',')

# Identify the previously mounted filesystems and remove them from the set of filesystems to mount
shared_dir_array.each_with_index do |dir, index|
  next unless node['cluster']['internal_shared_dirs'].include?(dir) || dir == "/home" || dir == "home" || dir == node['cluster']['internal_initial_shared_dir']
  shared_dir_array.delete(dir)
  id_array.delete_at(index)
  encryption_array.delete_at(index)
  iam_array.delete_at(index)
  access_point_id_array.delete_at(index)
end

# Mount EFS directories with the efs resource
efs "mount efs" do
  shared_dir_array shared_dir_array
  efs_fs_id_array id_array
  efs_encryption_in_transit_array encryption_array
  efs_iam_authorization_array iam_array
  efs_access_point_id_array access_point_id_array
  action :mount
  not_if { shared_dir_array.empty? }
end
