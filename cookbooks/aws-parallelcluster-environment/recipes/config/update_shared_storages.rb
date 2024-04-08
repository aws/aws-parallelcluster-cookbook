# frozen_string_literal: true

#
# Copyright:: 2013-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.
MOUNT_ACTION = "mount"
UNMOUNT_ACTION = "unmount"

# load shared storages data into node object
ruby_block "load shared storages mapping during cluster update" do
  block do
    require 'yaml'
    # regenerate the shared storages mapping file after update
    node.default['cluster']['shared_storages_mapping'] = YAML.safe_load(File.read(node['cluster']['previous_shared_storages_mapping_path']))
    node.default['cluster']['update_shared_storages_mapping'] = YAML.safe_load(File.read(node['cluster']['shared_storages_mapping_path']))
  end
end

ruby_block "get storage to mount and unmount" do
  block do
    # get ebs to unmount
    node.default['cluster']['unmount_shared_dir_array'], node.default['cluster']['unmount_vol_array'] = get_ebs(UNMOUNT_ACTION)
    # get ebs to mount
    node.default['cluster']['mount_shared_dir_array'], node.default['cluster']['mount_vol_array'] = get_ebs(MOUNT_ACTION)
    # get raid to unmount
    node.default['cluster']['unmount_raid_shared_dir'], node.default['cluster']['unmount_raid_type'], node.default['cluster']['unmount_raid_vol_array'] = get_raid(UNMOUNT_ACTION)
    # get raid to mount
    node.default['cluster']['mount_raid_shared_dir'], node.default['cluster']['mount_raid_type'], node.default['cluster']['mount_raid_vol_array'] = get_raid(MOUNT_ACTION)
    # get efs to unmount
    node.default['cluster']['unmount_efs_shared_dir_array'], node.default['cluster']['unmount_efs_fs_id_array'], = get_efs(UNMOUNT_ACTION)
    # get efs to mount
    node.default['cluster']['mount_efs_shared_dir_array'], node.default['cluster']['mount_efs_fs_id_array'], node.default['cluster']['mount_efs_encryption_in_transit_array'], node.default['cluster']['mount_efs_iam_authorization_array'] = get_efs(MOUNT_ACTION)
    # get fsx to unmount
    node.default['cluster']['unmount_fsx_fs_id_array'], node.default['cluster']['unmount_fsx_fs_type_array'], node.default['cluster']['unmount_fsx_shared_dir_array'], node.default['cluster']['unmount_fsx_dns_name_array'], node.default['cluster']['unmount_fsx_mount_name_array'], node.default['cluster']['unmount_fsx_volume_junction_path_array'] = get_fsx(UNMOUNT_ACTION)
    # get fsx to mount
    node.default['cluster']['mount_fsx_fs_id_array'], node.default['cluster']['mount_fsx_fs_type_array'], node.default['cluster']['mount_fsx_shared_dir_array'], node.default['cluster']['mount_fsx_dns_name_array'], node.default['cluster']['mount_fsx_mount_name_array'], node.default['cluster']['mount_fsx_volume_junction_path_array'] = get_fsx(MOUNT_ACTION)
  end

  def get_ebs(action)
    # get ebs to mount or unmount
    if action == UNMOUNT_ACTION
      in_shared_storages_mapping = node['cluster']['shared_storages_mapping']
      not_in_shared_storages_mapping = node['cluster']['update_shared_storages_mapping']
    elsif action == MOUNT_ACTION
      in_shared_storages_mapping = node['cluster']['update_shared_storages_mapping']
      not_in_shared_storages_mapping = node['cluster']['shared_storages_mapping']
    end
    shared_dir_array = []
    vol_array = []
    unless in_shared_storages_mapping["ebs"].nil?
      in_shared_storages_mapping["ebs"].each do |storage|
        next unless not_in_shared_storages_mapping["ebs"].nil? || !not_in_shared_storages_mapping["ebs"].include?(storage)
        shared_dir_array.push(storage["mount_dir"])
        vol_array.push(storage["volume_id"])
      end
    end
    [shared_dir_array, vol_array]
  end

  def get_efs(action)
    # get efs to mount or unmount
    if action == UNMOUNT_ACTION
      in_shared_storages_mapping = node['cluster']['shared_storages_mapping']
      not_in_shared_storages_mapping = node['cluster']['update_shared_storages_mapping']
    elsif action == MOUNT_ACTION
      in_shared_storages_mapping = node['cluster']['update_shared_storages_mapping']
      not_in_shared_storages_mapping = node['cluster']['shared_storages_mapping']
    end
    shared_dir_array = []
    efs_fs_id_array = []
    efs_encryption_in_transit_array = []
    efs_iam_authorization_array = []
    unless in_shared_storages_mapping["efs"].nil?
      in_shared_storages_mapping["efs"].each do |storage|
        next unless not_in_shared_storages_mapping["efs"].nil? || !not_in_shared_storages_mapping["efs"].include?(storage)
        shared_dir_array.push(storage["mount_dir"])
        efs_fs_id_array.push(storage["efs_fs_id"])
        # The EFS resource expects strings for these attributes, not booleans
        efs_encryption_in_transit_array.push(String(storage["efs_encryption_in_transit"]))
        efs_iam_authorization_array.push(String(storage["efs_iam_authorization"]))
      end
    end
    [shared_dir_array, efs_fs_id_array, efs_encryption_in_transit_array, efs_iam_authorization_array]
  end

  def get_fsx(action)
    # get fsx to mount or unmount
    if action == UNMOUNT_ACTION
      in_shared_storages_mapping = node['cluster']['shared_storages_mapping']
      not_in_shared_storages_mapping = node['cluster']['update_shared_storages_mapping']
    elsif action == MOUNT_ACTION
      in_shared_storages_mapping = node['cluster']['update_shared_storages_mapping']
      not_in_shared_storages_mapping = node['cluster']['shared_storages_mapping']
    end
    fsx_fs_id_array = []
    fsx_fs_type_array = []
    fsx_shared_dir_array = []
    fsx_dns_name_array = []
    fsx_mount_name_array = []
    fsx_volume_junction_path_array = []
    unless in_shared_storages_mapping["fsx"].nil?
      in_shared_storages_mapping["fsx"].each do |storage|
        next unless not_in_shared_storages_mapping["fsx"].nil? || !not_in_shared_storages_mapping["fsx"].include?(storage)

        fsx_fs_id_array.push(storage["fsx_fs_id"])
        fsx_fs_type_array.push(storage["fsx_fs_type"])
        fsx_shared_dir_array.push(storage["mount_dir"])
        fsx_dns_name_array.push(storage["fsx_dns_name"])
        fsx_mount_name_array.push(storage["fsx_mount_name"])
        fsx_volume_junction_path_array.push(storage["fsx_volume_junction_path"])
      end
    end
    [fsx_fs_id_array, fsx_fs_type_array, fsx_shared_dir_array, fsx_dns_name_array, fsx_mount_name_array, fsx_volume_junction_path_array]
  end

  def get_raid(action)
    # get raid to mount or unmount
    if action == UNMOUNT_ACTION
      in_shared_storages_mapping = node['cluster']['shared_storages_mapping']
      not_in_shared_storages_mapping = node['cluster']['update_shared_storages_mapping']
    elsif action == MOUNT_ACTION
      in_shared_storages_mapping = node['cluster']['update_shared_storages_mapping']
      not_in_shared_storages_mapping = node['cluster']['shared_storages_mapping']
    end
    raid_shared_dir = nil
    raid_type = nil
    raid_vol_array = []
    unless in_shared_storages_mapping["raid"].nil?
      in_shared_storages_mapping["raid"].each do |storage|
        next unless not_in_shared_storages_mapping["raid"].nil? || !not_in_shared_storages_mapping["raid"].include?(storage)
        raid_shared_dir = storage["raid_shared_dir"]
        raid_type = storage["raid_type"].to_s
        raid_vol_array = storage["raid_vol_array"]
      end
    end
    [raid_shared_dir, raid_type, raid_vol_array]
  end
end
# remove ebs
manage_ebs "remove ebs" do
  shared_dir_array(lazy { node['cluster']['unmount_shared_dir_array'] })
  vol_array(lazy { node['cluster']['unmount_vol_array'] })
  action %i(unexport unmount)
  not_if { node['cluster']['unmount_shared_dir_array'].empty? }
end

# add ebs
manage_ebs "add ebs" do
  shared_dir_array(lazy { node['cluster']['mount_shared_dir_array'] })
  vol_array(lazy { node['cluster']['mount_vol_array'] })
  action %i(mount export)
  not_if { node['cluster']['mount_shared_dir_array'].empty? }
end

# remove raid
raid "remove raid" do
  raid_shared_dir(lazy { node['cluster']['unmount_raid_shared_dir'] })
  raid_vol_array(lazy { node['cluster']['unmount_raid_vol_array'] })
  action %i(unexport unmount)
  not_if { node['cluster']['unmount_raid_shared_dir'].nil? }
end

# add raid
raid "add raid" do
  raid_shared_dir(lazy { node['cluster']['mount_raid_shared_dir'] })
  raid_type(lazy { node['cluster']['mount_raid_type'] })
  raid_vol_array(lazy { node['cluster']['mount_raid_vol_array'] })
  action %i(mount export)
  not_if { node['cluster']['mount_raid_shared_dir'].nil? }
end

# unmount efs
efs "unmount efs" do
  shared_dir_array(lazy { node['cluster']['unmount_efs_shared_dir_array'] })
  efs_fs_id_array(lazy { node['cluster']['unmount_efs_fs_id_array'] })
  action :unmount
  not_if { node['cluster']['unmount_efs_shared_dir_array'].empty? }
end

# mount efs
efs "mount efs" do
  shared_dir_array(lazy { node['cluster']['mount_efs_shared_dir_array'] })
  efs_fs_id_array(lazy { node['cluster']['mount_efs_fs_id_array'] })
  efs_encryption_in_transit_array(lazy { node['cluster']['mount_efs_encryption_in_transit_array'] })
  efs_iam_authorization_array(lazy { node['cluster']['mount_efs_iam_authorization_array'] })
  action :mount
  not_if { node['cluster']['mount_efs_shared_dir_array'].empty? }
end

# unmount fsx
lustre "unmount fsx" do
  fsx_fs_id_array(lazy { node['cluster']['unmount_fsx_fs_id_array'] })
  fsx_fs_type_array(lazy { node['cluster']['unmount_fsx_fs_type_array'] })
  fsx_shared_dir_array(lazy { node['cluster']['unmount_fsx_shared_dir_array'] })
  fsx_dns_name_array(lazy { node['cluster']['unmount_fsx_dns_name_array'] })
  fsx_mount_name_array(lazy { node['cluster']['unmount_fsx_mount_name_array'] })
  fsx_volume_junction_path_array(lazy { node['cluster']['unmount_fsx_volume_junction_path_array'] })
  action :unmount
  not_if { node['cluster']['unmount_fsx_fs_id_array'].empty? }
end

# mount fsx
lustre "mount fsx" do
  fsx_fs_id_array(lazy { node['cluster']['mount_fsx_fs_id_array'] })
  fsx_fs_type_array(lazy { node['cluster']['mount_fsx_fs_type_array'] })
  fsx_shared_dir_array(lazy { node['cluster']['mount_fsx_shared_dir_array'] })
  fsx_dns_name_array(lazy { node['cluster']['mount_fsx_dns_name_array'] })
  fsx_mount_name_array(lazy { node['cluster']['mount_fsx_mount_name_array'] })
  fsx_volume_junction_path_array(lazy { node['cluster']['mount_fsx_volume_junction_path_array'] })
  action :mount
  not_if { node['cluster']['mount_fsx_fs_id_array'].empty? }
end
