# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: head_node_base_config
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

# Get VPC CIDR
node.default['cluster']['ec2-metadata']['vpc-ipv4-cidr-blocks'] = get_vpc_ipv4_cidr_blocks(node['macaddress'])

# Parse shared directory info and turn into an array
shared_dir_array = node['cluster']['ebs_shared_dirs'].split(',')
shared_dir_array.each_with_index do |dir, index|
  shared_dir_array[index] = dir.strip
  shared_dir_array[index] = "/#{shared_dir_array[index]}" unless shared_dir_array[index].start_with?('/')
end

# Parse volume info into an array
vol_array = node['cluster']['volume'].split(',')
vol_array.each_with_index do |vol, index|
  vol_array[index] = vol.strip
end

# Mount each volume
dev_path = [] # device labels
dev_uuids = [] # device uuids

vol_array.each_with_index do |volumeid, index|
  # Skips volume if shared_dir is /NONE
  next if shared_dir_array[index] == "/NONE"

  ebs_shared_dir = shared_dir_array[index]
  dev_path[index] = "/dev/disk/by-ebs-volumeid/#{volumeid}"

  # Attach EBS volume
  execute "attach_volume_#{index}" do
    command "#{node.default['cluster']['cookbook_virtualenv_path']}/bin/python /usr/local/sbin/attachVolume.py #{volumeid}"
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
      dev_uuids[index] = get_uuid(dev_path[index])
    end
    action :nothing
    subscribes :run, "ruby_block[sleeping_for_volume_#{index}]", :immediately
  end

  fs_type = node['cluster']['volume_fs_type']

  mount_options = %w[_netdev]

  # Directories are shared from the head node towards the compute nodes.
  # So, the head node must copy the content of existing directories to the device before sharing them.
  if File.directory?(ebs_shared_dir)
    copy_to_device(ebs_shared_dir, dev_path[index], fs_type, mount_options)
  end

  # Create the EBS shared directories, if they do not exist
  directory ebs_shared_dir do
    owner 'root'
    group 'root'
    mode '1777'
    recursive true
    action :create
    not_if { ::File.directory?(ebs_shared_dir) }
  end

  # Add volume to /etc/fstab
  mount ebs_shared_dir do
    device(DelayedEvaluator.new { dev_uuids[index] })
    fstype fs_type
    device_type :uuid
    options mount_options.join(',')
    pass 0
    action %i[mount enable]
    retries 10
    retry_delay 6
  end
end

# NFS mounting for directories that must be shared by default.
# Only directories that are not EFS/FSx mounted require this.
directories_shared_by_default = %w[/home /opt/intel]
directories_shared_via_nfs = directories_shared_by_default.select{ |directory|
  ::File.directory?(directory) && !efs_mounted?(directory) && !fsx_mounted?(directory)
}
directories_shared_via_nfs.each do |directory|
  nfs_export directory do
    network node['cluster']['ec2-metadata']['vpc-ipv4-cidr-blocks']
    writeable true
    options ['no_root_squash']
  end
end

# Setup RAID array on head node
include_recipe 'aws-parallelcluster::setup_raid_on_head_node'

# Setup cluster user
user node['cluster']['cluster_user'] do
  manage_home true
  comment 'AWS ParallelCluster user'
  home "/home/#{node['cluster']['cluster_user']}"
  shell '/bin/bash'
end

# Setup SSH auth for cluster user
bash "ssh-keygen" do
  cwd "/home/#{node['cluster']['cluster_user']}"
  code <<-KEYGEN
    set -e
    su - #{node['cluster']['cluster_user']} -c \"ssh-keygen -q -t rsa -f ~/.ssh/id_rsa -N ''\"
  KEYGEN
  not_if { ::File.exist?("/home/#{node['cluster']['cluster_user']}/.ssh/id_rsa") }
end

bash "copy_and_perms" do
  cwd "/home/#{node['cluster']['cluster_user']}"
  code <<-PERMS
    set -e
    su - #{node['cluster']['cluster_user']} -c \"cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && chmod 0600 ~/.ssh/authorized_keys && touch ~/.ssh/authorized_keys_cluster\"
  PERMS
  not_if { ::File.exist?("/home/#{node['cluster']['cluster_user']}/.ssh/authorized_keys_cluster") }
end

bash "ssh-keyscan" do
  cwd "/home/#{node['cluster']['cluster_user']}"
  code <<-KEYSCAN
    set -e
    su - #{node['cluster']['cluster_user']} -c \"ssh-keyscan #{node['hostname']} > ~/.ssh/known_hosts && chmod 0600 ~/.ssh/known_hosts\"
  KEYSCAN
  not_if { ::File.exist?("/home/#{node['cluster']['cluster_user']}/.ssh/known_hosts") }
end

if node['cluster']['dcv_enabled'] == "head_node"
  # Activate DCV on head node
  include_recipe 'aws-parallelcluster::dcv_config'
end

# IMDS
include_recipe 'aws-parallelcluster::imds_config'
