# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: install_slurm
#
# Copyright:: 2013-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

slurm_user = node['cluster']['slurm']['user']
slurm_user_id = node['cluster']['slurm']['user_id']
slurm_group = node['cluster']['slurm']['group']
slurm_group_id = node['cluster']['slurm']['group_id']
cluster_admin_slurm_share_group = node['cluster']['cluster_admin_slurm_share_group']
cluster_admin_slurm_share_group_id = node['cluster']['cluster_admin_slurm_share_group_id']

# Setup slurm group
group slurm_group do
  comment 'slurm group'
  gid slurm_group_id
  system true
end

# Setup slurm user
user slurm_user do
  comment 'slurm user'
  uid slurm_user_id
  gid slurm_group_id
  # home is mounted from the head node
  manage_home ['HeadNode', nil].include?(node['cluster']['node_type'])
  home "/home/#{slurm_user}"
  system true
  shell '/bin/bash'
end

# Setup cluster admin slurm share group
group cluster_admin_slurm_share_group do
  comment 'slurm resume program group'
  gid cluster_admin_slurm_share_group_id
  system true
end

# add slurm user and pcluster-admin to share group
group cluster_admin_slurm_share_group do
  action :modify
  members [ slurm_user, node['cluster']['cluster_admin_user'] ]
  append true
end
