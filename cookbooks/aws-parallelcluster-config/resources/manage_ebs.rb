# frozen_string_literal: true

# Copyright:: 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance
# with the License. A copy of the License is located at http://aws.amazon.com/apache2.0/
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

resource_name :manage_ebs
provides :manage_ebs
unified_mode true

property :shared_dir_array, Array, required: true
property :vol_array, Array, required: true

default_action :mount

action :mount do
  shared_dir_array = new_resource.shared_dir_array.dup
  vol_array = new_resource.vol_array.dup

  shared_dir_array.each_with_index do |dir, index|
    shared_dir_array[index] = format_directory(dir)
  end

  vol_array.each_with_index do |vol, index|
    vol_array[index] = vol.strip
  end

  # Mount each volume
  dev_path = [] # device labels

  vol_array.each_with_index do |volumeid, index|
    dev_path[index] = "/dev/disk/by-ebs-volumeid/#{volumeid}"

    # Attach EBS volume
    execute "attach_volume_#{index}" do
      command "#{cookbook_virtualenv_path}/bin/python /usr/local/sbin/manageVolume.py --volume-id #{volumeid} --attach"
      creates dev_path[index]
    end

    # wait for the drive to attach, before making a filesystem
    ruby_block "sleeping_for_volume_#{index}" do
      block do
        wait_for_block_dev(dev_path[index])
      end
      action :nothing
      subscribes :run, "execute[attach_volume_#{index}]", :immediately
    end

    # Setup disk, will be formatted xfs if empty
    ruby_block "setup_disk_#{index}" do
      block do
        pt_type = get_pt_type(dev_path[index])
        if pt_type.nil?
          Chef::Log.info("device #{dev_path[index]} not partitioned, mounting directly")
          fs_type = setup_disk(dev_path[index])
        else
          # Partitioned device, mount 1st partition
          Chef::Log.info("device #{dev_path[index]} partitioned, mounting first partition")
          partition_dev = get_1st_partition(dev_path[index])
          Chef::Log.info("First partition for device #{dev_path[index]} is: #{partition_dev}")
          fs_type = get_fs_type(partition_dev)
          dev_path[index] = partition_dev
        end
        node.default['cluster']['volume_fs_type'] = fs_type
      end
      action :nothing
      subscribes :run, "ruby_block[sleeping_for_volume_#{index}]", :immediately
    end

    # Create the shared directories
    directory shared_dir_array[index] do
      owner 'root'
      group 'root'
      mode '1777'
      recursive true
      action :create
    end

    # Add volume to /etc/fstab
    mount shared_dir_array[index] do
      device(DelayedEvaluator.new { get_uuid(dev_path[index]) })
      fstype(DelayedEvaluator.new { node['cluster']['volume_fs_type'] })
      device_type :uuid
      options "_netdev"
      pass 0
      action :mount
      retries 10
      retry_delay 6
      not_if "mount | grep ' #{shared_dir_array[index]} '"
    end

    mount shared_dir_array[index] do
      device(DelayedEvaluator.new { get_uuid(dev_path[index]) })
      fstype(DelayedEvaluator.new { node['cluster']['volume_fs_type'] })
      device_type :uuid
      options "_netdev"
      pass 0
      action :enable
      retries 10
      retry_delay 6
      only_if "mount | grep ' #{shared_dir_array[index]} '"
    end

    # Make sure shared directory permissions are correct
    directory shared_dir_array[index] do
      owner 'root'
      group 'root'
      mode '1777'
    end
  end
end

action :export do
  shared_dir_array = new_resource.shared_dir_array.dup

  shared_dir_array.each_with_index do |dir, index|
    shared_dir_array[index] = format_directory(dir)
    # Export shared dir
    nfs_export shared_dir_array[index] do
      network get_vpc_cidr_list
      writeable true
      options ['no_root_squash']
    end
  end
end

action :unmount do
  shared_dir_array = new_resource.shared_dir_array.dup
  vol_array = new_resource.vol_array.dup

  shared_dir_array.each_with_index do |dir, index|
    shared_dir_array[index] = format_directory(dir)
  end

  vol_array.each_with_index do |vol, index|
    vol_array[index] = vol.strip
  end

  # Mount each volume
  dev_path = [] # device labels

  vol_array.each_with_index do |volumeid, index|
    dev_path[index] = "/dev/disk/by-ebs-volumeid/#{volumeid}"

    # Unmount and remove volume from /etc/fstab
    execute 'unmount ebs' do
      command "umount -fl #{shared_dir_array[index]}"
      retries 10
      retry_delay 6
      timeout 60
      only_if "mount | grep ' #{shared_dir_array[index]} '"
    end

    # remove volume from fstab
    delete_lines "remove volume from /etc/fstab" do
      path "/etc/fstab"
      pattern " #{shared_dir_array[index]} "
    end

    # Detach EBS volume
    execute "detach_volume_#{index}" do
      command "#{cookbook_virtualenv_path}/bin/python /usr/local/sbin/manageVolume.py --volume-id #{volumeid} --detach"
    end

    # Delete the shared directories
    directory shared_dir_array[index] do
      recursive true
      action :delete
    end
  end
end

action :unexport do
  shared_dir_array = new_resource.shared_dir_array.dup

  shared_dir_array.each_with_index do |dir, index|
    shared_dir_array[index] = format_directory(dir)
    # unexport the volume
    delete_lines "remove volume from /etc/exports" do
      path "/etc/exports"
      pattern "^#{shared_dir_array[index]} "
    end
  end

  execute "unexport volume" do
    command "exportfs -ra"
  end
end

action_class do
  def get_uuid_for_unmount(mount_dir)
    cmd = Mixlib::ShellOut.new("lsblk -f | grep #{mount_dir} | awk '{{print $3}}'")
    cmd.run_command.stdout.strip
  end
end
