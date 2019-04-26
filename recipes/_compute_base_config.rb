#
# Cookbook Name:: aws-parallelcluster
# Recipe:: _compute_base_config
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

nfs_master = node['cfncluster']['cfn_master']

# Mount EFS directory with efs_mount recipe
include_recipe 'aws-parallelcluster::efs_mount'

# Parse and get RAID shared directory info and turn into an array
raid_shared_dir = node['cfncluster']['cfn_raid_parameters'].split(',')[0]

if raid_shared_dir != "NONE"
  # Path needs to be fully qualified, for example "shared/temp" becomes "/shared/temp"
  raid_shared_dir = "/" + raid_shared_dir unless raid_shared_dir.start_with?("/")

  # Created RAID shared mount point
  directory raid_shared_dir do
    mode '1777'
    owner 'root'
    group 'root'
    action :create
  end

  # Mount RAID directory over NFS
  mount raid_shared_dir do
    device "#{nfs_master}:#{raid_shared_dir}"
    fstype 'nfs'
    options 'hard,intr,noatime,vers=3,_netdev'
    action %i[mount enable]
  end
end

# Mount /home over NFS
mount '/home' do
  device "#{nfs_master}:/home"
  fstype 'nfs'
  options 'hard,intr,noatime,vers=3,_netdev'
  action %i[mount enable]
end

# Configure Ganglia
if node['cfncluster']['ganglia_enabled'] == "yes"
  template '/etc/ganglia/gmond.conf' do
    source 'gmond.conf.erb'
    owner 'root'
    group 'root'
    mode '0644'
  end

  service node['cfncluster']['ganglia']['gmond_service'] do
    supports restart: true
    action %i[enable restart]
  end
end

# Setup cluster user
user node['cfncluster']['cfn_cluster_user'] do
  manage_home false
  comment 'cfncluster user'
  home "/home/#{node['cfncluster']['cfn_cluster_user']}"
  shell '/bin/bash'
end

# Parse shared directory info and turn into an array
shared_dir_array = node['cfncluster']['cfn_shared_dir'].split(',')
shared_dir_array.each_with_index do |dir, index|
  shared_dir_array[index] = dir.strip
  shared_dir_array[index] = "/" + shared_dir_array[index] unless shared_dir_array[index].start_with?("/")
end

# Mount each volume with NFS
shared_dir_array.each do |dirname|
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
    device "#{nfs_master}:#{dirname}"
    fstype 'nfs'
    options 'hard,intr,noatime,vers=3,_netdev'
    action %i[mount enable]
  end
end

# Install nodewatcher.cfg
template '/etc/nodewatcher.cfg' do
  source 'nodewatcher.cfg.erb'
  owner 'root'
  group 'root'
  mode '0644'
end
