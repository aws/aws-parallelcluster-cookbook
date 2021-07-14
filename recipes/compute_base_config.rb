# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: compute_base_config
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

# Retrieve head node info
if node['cluster']['scheduler'] == 'slurm'
  ruby_block "retrieve head_node ip" do
    block do
      head_node_private_ip, head_node_private_dns = hit_head_node_info
      node.force_default['cluster']['head_node'] = head_node_private_dns
      node.force_default['cluster']['head_node_private_ip'] = head_node_private_ip
    end
    retries 5
    retry_delay 3
  end
end

# Parse and get RAID shared directory info and turn into an array
raid_shared_dir = node['cluster']['raid_parameters'].split(',')[0]

if raid_shared_dir != "NONE"
  # Path needs to be fully qualified, for example "shared/temp" becomes "/shared/temp"
  raid_shared_dir = "/#{raid_shared_dir}" unless raid_shared_dir.start_with?('/')

  # Created RAID shared mount point
  directory raid_shared_dir do
    mode '1777'
    owner 'root'
    group 'root'
    action :create
    not_if { ::File.directory?(raid_shared_dir) }
  end

  # Mount RAID directory over NFS
  mount raid_shared_dir do
    device(lazy { "#{node['cluster']['head_node_private_ip']}:#{raid_shared_dir}" })
    fstype 'nfs'
    options node['cluster']['nfs']['hard_mount_options']
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
  mount directory do
    device(lazy { "#{node['cluster']['head_node_private_ip']}:#{directory}" })
    fstype 'nfs'
    options node['cluster']['nfs']['hard_mount_options']
    action %i[mount enable]
    retries 10
    retry_delay 6
  end
end

# Setup cluster user
user node['cluster']['cluster_user'] do
  manage_home false
  comment 'AWS ParallelCluster user'
  home "/home/#{node['cluster']['cluster_user']}"
  shell '/bin/bash'
end

# Parse shared directory info and turn into an array
shared_dir_array = node['cluster']['ebs_shared_dirs'].split(',')

# Mount each volume with NFS
shared_dir_array.each do |dir|
  dirname = dir.strip

  next if dirname == "NONE"

  dirname = "/#{dirname}" unless dirname.start_with?('/')

  # Created shared mount point, if it does not exist
  directory dirname do
    mode '1777'
    owner 'root'
    group 'root'
    recursive true
    action :create
    not_if { ::File.directory?(dirname) }
  end

  # Mount shared volume over NFS
  mount dirname do
    device(lazy { "#{node['cluster']['head_node_private_ip']}:#{dirname}" })
    fstype 'nfs'
    options node['cluster']['nfs']['hard_mount_options']
    action %i[mount enable]
    retries 10
    retry_delay 6
  end
end

# IMDS
include_recipe 'aws-parallelcluster::imds_config'
