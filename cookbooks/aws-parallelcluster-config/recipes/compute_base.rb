# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: compute_base
#
# Copyright 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

# Mount /home over NFS
mount '/home' do
  device(lazy { "#{node['cluster']['head_node_private_ip']}:/home" })
  fstype 'nfs'
  options node['cluster']['nfs']['hard_mount_options']
  action %i[mount enable]
  retries 10
  retry_delay 6
end

# Mount /opt/intel over NFS
mount '/opt/intel' do
  device(lazy { "#{node['cluster']['head_node_private_ip']}:/opt/intel" })
  fstype 'nfs'
  options node['cluster']['nfs']['hard_mount_options']
  action %i[mount enable]
  retries 10
  retry_delay 6
  only_if { ::File.directory?("/opt/intel") }
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

  # Created shared mount point
  directory dirname do
    mode '1777'
    owner 'root'
    group 'root'
    recursive true
    action :create
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
include_recipe 'aws-parallelcluster-config::imds'
