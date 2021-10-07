# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: user
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

# Setup scheduler group
group node['cluster']['scheduler']['group'] do
  comment 'scheduler group'
  gid node['cluster']['scheduler']['group_id']
  system true
end

# Setup scheduler user
user node['cluster']['scheduler']['user'] do
  comment 'scheduler user'
  uid node['cluster']['scheduler']['user_id']
  gid node['cluster']['scheduler']['group_id']
  # home is mounted from the head node
  manage_home ['HeadNode', nil].include?(node['cluster']['node_type'])
  home "/home/#{node['cluster']['scheduler']['user']}"
  system true
  shell '/bin/bash'
end

# create e.g. /opt/parallelcluster/scheduler
scheduler_opt_path = File.join(node['cluster']['scheduler']['opt_path'], node['cluster']['scheduler']['name'])
directory scheduler_opt_path do
  owner node['cluster']['scheduler']['user']
  group node['cluster']['scheduler']['user']
  mode '0755'
  action :create
end

# create e.g. /opt/parallelcluster/shared/scheduler
scheduler_opt_shared_path = File.join(node['cluster']['scheduler']['opt_shared_path'], node['cluster']['scheduler']['name'])
directory scheduler_opt_shared_path do
  owner node['cluster']['scheduler']['user']
  group node['cluster']['scheduler']['user']
  mode '0755'
  action :create
end
