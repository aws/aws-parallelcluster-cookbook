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
id_array = node['cluster']['fsx_fs_ids'].split(',')
type_array = node['cluster']['fsx_fs_types'].split(',')
shared_dir_array = node['cluster']['fsx_shared_dirs'].split(',')
dns_name_array = node['cluster']['fsx_dns_names'].split(',')
mount_name_array = node['cluster']['fsx_mount_names'].split(',')
volume_junction_path_array = node['cluster']['fsx_volume_junction_paths'].split(',')

# Identify the previously mounted filesystems and remove them from the set of filesystems to mount
shared_dir_array.each_with_index do |dir, index|
  next unless dir == "/home" || dir == 'home'
  id_array.delete_at(index)
  type_array.delete_at(index)
  shared_dir_array.delete(dir)
  dns_name_array.delete_at(index)
  mount_name_array.delete_at(index)
  volume_junction_path_array.delete_at(index)
end

# Mount FSx shared directories with the lustre resource
lustre "mount fsx" do
  fsx_fs_id_array id_array
  fsx_fs_type_array type_array
  fsx_shared_dir_array shared_dir_array
  fsx_dns_name_array dns_name_array
  fsx_mount_name_array mount_name_array
  fsx_volume_junction_path_array volume_junction_path_array
  action :mount
  not_if { id_array.empty? }
end
