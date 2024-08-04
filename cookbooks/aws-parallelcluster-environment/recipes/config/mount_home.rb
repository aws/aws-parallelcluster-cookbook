# frozen_string_literal: true

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

return if on_docker?

shared_storage = { 'efs' => node['cluster']['efs_shared_dirs'].split(','),
                   'fsx' => node['cluster']['fsx_shared_dirs'].split(','),
                   'ebs' => node['cluster']['ebs_shared_dirs'].split(','),
                   # Making sure they are all the same object type, even though raid is just a string
                   'raid' => node['cluster']['raid_shared_dir'].split(','),
}

# Check if home is a shared filesystem
shared_home = 'none'
shared_home = 'internal' if node['cluster']['shared_storage_type'] == 'efs'
shared_storage.each do |type, dirs|
  next unless dirs.include?('/home') || dirs.include?('home')
  shared_home = type
  break
end

if shared_home == 'none'
  # Mount the NFS export to compute and login nodes, the head node will export /home later
  case node['cluster']['node_type']
  when 'ComputeFleet', 'LoginNode'
    volume "mount /home" do
      action :mount
      shared_dir '/home'
      device(lazy { "#{node['cluster']['head_node_private_ip']}:#{node['cluster']['head_node_home_path']}" })
      fstype 'nfs'
      options node['cluster']['nfs']['hard_mount_options']
      retries 10
      retry_delay 6
    end
  when 'HeadNode'
    Chef::Log.info("Do not mount NFS shares on the HeadNode")
  else
    raise "node_type must be ComputeFleet, LoginNode or HeadNode"
  end
else
  # Identify the filesystem that is shared and mount it
  include_recipe "aws-parallelcluster-environment::update_fs_mapping"
  include_recipe "aws-parallelcluster-environment::backup_home_shared_data"
  case shared_home
  when 'internal'
    shared_storage['efs'].each_with_index do |dir, index|
      next unless dir == node['cluster']['internal_initial_shared_dir']
      efs "mount internal shared efs home" do
        shared_dir_array ['/home']
        efs_fs_id_array [node['cluster']['efs_fs_ids'].split(',')[index]]
        efs_encryption_in_transit_array [node['cluster']['efs_encryption_in_transits'].split(',')[index]]
        efs_iam_authorization_array [node['cluster']['efs_iam_authorizations'].split(',')[index]]
        efs_mount_point_array ['/home']
        efs_access_point_id [node['cluster']['efs_access_point_ids'].split(',')[index]]
        action :mount
      end
      break
    end
  when 'efs'
    shared_storage['efs'].each_with_index do |dir, index|
      next unless dir == "/home" || dir == 'home'
      efs "mount shared efs home" do
        shared_dir_array [dir]
        efs_fs_id_array [node['cluster']['efs_fs_ids'].split(',')[index]]
        efs_encryption_in_transit_array [node['cluster']['efs_encryption_in_transits'].split(',')[index]]
        efs_iam_authorization_array [node['cluster']['efs_iam_authorizations'].split(',')[index]]
        efs_access_point_id [node['cluster']['efs_access_point_ids'].split(',')[index]]
        action :mount
      end
      break
    end
  when 'fsx'
    shared_storage['fsx'].each_with_index do |dir, index|
      next unless dir == "/home" || dir == 'home'
      lustre "mount shared fsx home" do
        fsx_fs_id_array [node['cluster']['fsx_fs_ids'].split(',')[index]]
        fsx_fs_type_array [node['cluster']['fsx_fs_types'].split(',')[index]]
        fsx_shared_dir_array [dir]
        fsx_dns_name_array [node['cluster']['fsx_dns_names'].split(',')[index]]
        fsx_mount_name_array [node['cluster']['fsx_mount_names'].split(',')[index]]
        fsx_volume_junction_path_array [node['cluster']['fsx_volume_junction_paths'].split(',')[index]]
        action :mount
      end
      break
    end
  when 'ebs'
    case node['cluster']['node_type']
    when 'HeadNode'
      shared_storage['ebs'].each_with_index do |dir, index|
        next unless dir == "/home" || dir == 'home'
        manage_ebs "add ebs /home" do
          shared_dir_array [dir]
          vol_array [node['cluster']['volume'].split(',')[index]]
          action %i(mount export)
        end
        break
      end
    when 'ComputeFleet', 'LoginNode'
      volume "mount /home" do
        action :mount
        shared_dir '/home'
        device(lazy { "#{node['cluster']['head_node_private_ip']}:#{format_directory('/home')}" })
        fstype 'nfs'
        options node['cluster']['nfs']['hard_mount_options']
        retries 10
        retry_delay 6
      end
    end
  when 'raid'
    case node['cluster']['node_type']
    when 'HeadNode'
      raid "add raid /home" do
        raid_shared_dir '/home'
        raid_type node['cluster']['raid_type']
        raid_vol_array node['cluster']['raid_vol_ids'].split(',')
        action %i(mount export)
      end
    when 'ComputeFleet', 'LoginNode'
      volume "mount raid /home volume over NFS" do
        action :mount
        shared_dir '/home'
        device(lazy { "#{node['cluster']['head_node_private_ip']}:/home" })
        fstype 'nfs'
        options node['cluster']['nfs']['hard_mount_options']
        retries 10
        retry_delay 6
      end
    end
  end
  include_recipe "aws-parallelcluster-environment::restore_home_shared_data"
end
