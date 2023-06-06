# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: head_node_base
#
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

# generate the shared storages mapping file
include_recipe 'aws-parallelcluster-environment::fs_update'

manage_ebs "add ebs" do
  shared_dir_array node['cluster']['ebs_shared_dirs'].split(',')
  vol_array node['cluster']['volume'].split(',')
  action %i(mount export)
  not_if { node['cluster']['ebs_shared_dirs'].split(',').empty? }
end unless on_docker?

# Export /home
nfs_export "/home" do
  network get_vpc_cidr_list
  writeable true
  options ['no_root_squash']
end unless on_docker?

# Export /opt/parallelcluster/shared
nfs_export node['cluster']['shared_dir'] do
  network get_vpc_cidr_list
  writeable true
  options ['no_root_squash']
end unless on_docker?

# Export /opt/intel if it exists
nfs_export "/opt/intel" do
  network get_vpc_cidr_list
  writeable true
  options ['no_root_squash']
  only_if { ::File.directory?("/opt/intel") }
end unless on_docker?

# Setup RAID array on head node
include_recipe 'aws-parallelcluster-config::head_node_raid'

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
  dcv "Configure DCV" do
    action :configure
  end
end unless on_docker?

unless node['cluster']['scheduler'] == 'awsbatch'
  include_recipe 'aws-parallelcluster-computefleet::head_node_fleet_status'
end
