#
# Cookbook Name:: cfncluster
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

# Created shared mount point
directory node['cfncluster']['cfn_shared_dir'] do
  mode '1777'
  owner 'root'
  group 'root'
  recursive true
  action :create
end

node.default['cfncluster']['cfn_master'] = node['cfncluster']['cfn_master'].split('.')[0]

nfs_master = node['cfncluster']['cfn_master']

# Mount shared volume over NFS
mount node['cfncluster']['cfn_shared_dir'] do
  device "#{nfs_master}:#{node['cfncluster']['cfn_shared_dir']}"
  fstype 'nfs'
  options 'hard,intr,noatime,vers=3,_netdev'
  action %i[mount enable]
end

# Mount /home over NFS
mount '/home' do
  device "#{nfs_master}:/home"
  fstype 'nfs'
  options 'hard,intr,noatime,vers=3,_netdev'
  action %i[mount enable]
end

# Configure Ganglia
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

# Setup cluster user
user node['cfncluster']['cfn_cluster_user'] do
  supports manage_home: false
  comment 'cfncluster user'
  home "/home/#{node['cfncluster']['cfn_cluster_user']}"
  shell '/bin/bash'
end

# Install nodewatcher.cfg
template '/etc/nodewatcher.cfg' do
  source 'nodewatcher.cfg.erb'
  owner 'root'
  group 'root'
  mode '0644'
end
