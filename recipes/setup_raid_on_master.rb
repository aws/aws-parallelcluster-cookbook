#
# Cookbook Name:: aws-parallelcluster
# Recipe:: setup_raid_on_master
#
# Copyright 2013-2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# RAID RELATED
# Parse and get RAID shared directory info and turn into an array
raid_shared_dir = node['cfncluster']['cfn_raid_parameters'].split(',')[0]

if raid_shared_dir != "NONE"

  # Parse and determine RAID type (cast into integer)
  raid_type = node['cfncluster']['cfn_raid_parameters'].split(',')[1].strip.to_i

  # Parse volume info into an array
  raid_vol_array = node['cfncluster']['cfn_raid_vol_ids'].split(',')
  raid_vol_array.each_with_index do |vol, index|
      raid_vol_array[index] = vol.strip
  end

  # Attach each volume
  raid_dev_path = []
  raid_vol_array.each_with_index do |volumeid, index|
      raid_dev_path[index] = "/dev/disk/by-ebs-volumeid/#{volumeid}"

      # Attach RAID EBS volume
      execute "attach_raid_volume_#{index}" do
          command "/usr/local/sbin/attachVolume.py #{volumeid}"
          creates raid_dev_path[index]
      end

      # wait for the drive to attach
      ruby_block "sleeping_for_raid_volume_#{index}" do
        block do
           wait_for_block_dev(raid_dev_path[index])
           puts "Attached index: #{index}, VolID: #{volumeid}"
        end
        action :nothing
        subscribes :run, "execute[attach_raid_volume_#{index}]", :immediately
      end
  end

  raid_dev = "/dev/md0"

  # Create RAID device with mdadm
  mdadm "MY_RAID" do
      raid_device raid_dev
      level raid_type
      devices raid_dev_path
  end

  # Wait for RAID to initialize
  ruby_block "sleeping_for_raid_block" do
    block do
       wait_for_block_dev(raid_dev)
    end
    action :nothing
    subscribes :run, "mdadm[MY_RAID]", :immediately
  end

  # Setup RAID disk, create ext4 filesystem on RAID array
  execute "setup_raid_disk" do
    command "sudo mkfs.ext4 #{raid_dev}"
    action :nothing
    subscribes :run, "ruby_block[sleeping_for_raid_block]", :immediately
  end


  # Create a configuration file to contain the RAID info, so the RAID array is reassembled automatically on boot
  if node['cfncluster']['cfn_base_os'] != "ubuntu1404"
      execute "create_raid_config" do
        command "sudo mdadm --detail --scan | sudo tee -a /etc/mdadm.conf"
        action :nothing
        subscribes :run, "execute[setup_raid_disk]", :immediately
      end

  else
      # Put config file in /etc/mdadm/mdadm.conf, Ubuntu1404 specific
      execute "create_raid_config" do
        command "sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf"
        action :nothing
        subscribes :run, "execute[setup_raid_disk]", :immediately
      end
      # Update initramfs to contain mdadm.conf settings, Ubuntu1404 specific
      execute "update_raid_config" do
        command "sudo update-initramfs -u"
        action :nothing
        subscribes :run, "execute[setup_raid_disk]", :immediately
      end
  end

  # Create the shared directory
  directory raid_shared_dir do
    owner 'root'
    group 'root'
    mode '1777'
    recursive true
    action :create
  end

  # Add volume to /etc/fstab
  mount raid_shared_dir do
    device "/dev/md0"
    fstype "ext4"
    options "defaults,nofail,_netdev"
    action %i[mount enable]
  end

  # Make sure shared directory permissions are correct
  directory raid_shared_dir do
    owner 'root'
    group 'root'
    mode '1777'
  end

  # Export RAID directory via nfs
  nfs_export raid_shared_dir do
    network node['cfncluster']['ec2-metadata']['vpc-ipv4-cidr-block']
    writeable true
    options ['no_root_squash']
  end
end
