# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster-byos
# Recipe:: install_user
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

# Setup byos group
group node['cluster']['byos']['group'] do
  comment 'byos group'
  gid node['cluster']['byos']['group_id']
  system true
end

# Setup byos user
user node['cluster']['byos']['user'] do
  comment 'byos user'
  uid node['cluster']['byos']['user_id']
  gid node['cluster']['byos']['group_id']
  # home is mounted from the head node
  manage_home true
  home "/home/#{node['cluster']['byos']['user']}"
  system true
  shell '/bin/bash'
end

# Reserve byos system users that will be replaced at node configuration time.
(0..9).each do |i|
  user node['cluster']['byos']['user'] + i.to_s do
    comment "byos system user #{i}"
    uid node['cluster']['byos']['system_user_id_start'] + i
    gid node['cluster']['byos']['system_user_id_start'] + i
  end
end

# create dir /home/byos/.parallelcluster
directory node['cluster']['byos']['handler_dir'] do
  owner node['cluster']['byos']['user']
  group node['cluster']['byos']['user']
  mode '0755'
  action :create
end

# Ensure byos user has sudoers capability
template '/etc/sudoers.d/99-parallelcluster-byos' do
  source 'byos_user/99-parallelcluster-byos.erb'
  owner 'root'
  group 'root'
  mode '0600'
end
