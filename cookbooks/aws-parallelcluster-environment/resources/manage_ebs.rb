# frozen_string_literal: true

# Copyright:: 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance
# with the License. A copy of the License is located at http://aws.amazon.com/apache2.0/
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

provides :manage_ebs
unified_mode true

property :shared_dir_array, Array, required: %i(mount export unmount unexport)
property :vol_array, Array, required: %i(mount unmount)

default_action :mount

action :mount do
  return if on_docker?
  shared_dir_array = new_resource.shared_dir_array.dup
  vol_array = new_resource.vol_array.dup

  # Mount each volume
  dev_path = [] # device labels

  vol_array.each_with_index do |volumeid, index|
    dev_path[index] = "/dev/disk/by-ebs-volumeid/#{volumeid}"

    volume "attach volume #{index}" do
      volume_id volumeid
      action :attach
    end

    # Setup disk, will be formatted xfs if empty
    ruby_block "setup_disk_#{index}" do
      block do
        dev_path[index] = prepare_disk(dev_path[index])
      end
      action :nothing
      subscribes :run, "volume[attach volume #{index}]", :immediately
    end

    volume "mount volume #{index}" do
      action :mount
      shared_dir shared_dir_array[index]
      device(lazy_uuid(dev_path[index]))
      fstype(DelayedEvaluator.new { node['cluster']['volume_fs_type'] })
      device_type :uuid
      options "_netdev"
      retries 10
      retry_delay 6
    end
  end
end

action :export do
  return if on_docker?
  new_resource.shared_dir_array.dup.each do |dir|
    volume "export volume #{dir}" do
      shared_dir dir
      action :export
    end
  end
end

action :unmount do
  return if on_docker?
  new_resource.vol_array.each_with_index do |volumeid, index|
    volume "unmount volume #{index}" do
      shared_dir new_resource.shared_dir_array[index]
      action :unmount
    end

    volume "detach volume #{index}" do
      volume_id volumeid
      action :detach
    end
  end
end

action :unexport do
  return if on_docker?
  new_resource.shared_dir_array.dup.each do |dir|
    volume "unexport volume #{dir}" do
      shared_dir dir
      action :unexport
    end
  end
end

def lazy_uuid(device)
  DelayedEvaluator.new { get_uuid(device) }
end

#
# Gets the uuid of a device
#
def get_uuid(device)
  Chef::Log.info("Getting uuid for device: #{device}")
  match = shell_out("blkid -c /dev/null #{device}").stdout.match(/\sUUID="(.*?)"/)
  match = '' if match.nil?
  Chef::Log.info("uuid for device: #{device} is #{match[1]}")
  match[1]
end

#
# Checks if device is partitioned; if yes returns pt type
#
def get_pt_type(device)
  match = shell_out("blkid -c /dev/null #{device}").stdout.match(/\sPTTYPE="(.*?)"/)
  match = '' if match.nil?

  Chef::Log.info("Partition type for device #{device}: #{match[1]}")
  match[1]
end

#
# Check if block device has a filesystem
#
def get_fs_type(device)
  match = shell_out("blkid -c /dev/null #{device}").stdout.match(/\sTYPE="(.*?)"/)
  match = '' if match.nil?

  Chef::Log.info("File system type for device #{device}: #{match[1]}")
  match[1]
end

#
# Format a block device using the EXT4 file system if it is not already
# formatted.
#
def setup_disk(path)
  dev = ::File.readlink(path)
  full_path = ::File.absolute_path(dev, ::File.dirname(path))

  fs_type = get_fs_type(full_path)
  if fs_type.nil?
    shell_out("mkfs.ext4 #{full_path}")
    fs_type = 'ext4'
  end

  fs_type
end

#
# Returns the first partition of a device, provided via sym link
#
def get_1st_partition(device)
  # Resolves the real device name (ex. /dev/sdg)
  Chef::Log.info("Getting 1st partition for device: #{device}")
  partition = "/dev/#{shell_out("lsblk -ln -o Name #{device}|awk 'NR==2'").stdout.strip}"
  Chef::Log.info("1st partition for device: #{device} is: #{partition}")
  partition
end

def prepare_disk(device_path)
  pt_type = get_pt_type(device_path)
  if pt_type.nil?
    Chef::Log.info("device #{device_path} not partitioned, mounting directly")
    fs_type = setup_disk(device_path)
  else
    # Partitioned device, mount 1st partition
    Chef::Log.info("device #{device_path} partitioned, mounting first partition")
    partition_dev = get_1st_partition(device_path)
    Chef::Log.info("First partition for device #{device_path} is: #{partition_dev}")
    fs_type = get_fs_type(partition_dev)
    device_path = partition_dev
  end
  node.default['cluster']['volume_fs_type'] = fs_type
  device_path
end
