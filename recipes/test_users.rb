# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: tests_users
#
# Copyright 2013-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

###################
# Cluster admin user
###################
check_user_definition(
  node['cluster']['cluster_admin_user'],
  node['cluster']['cluster_admin_user_id'],
  node['cluster']['cluster_admin_group_id'],
  "AWS ParallelCluster Admin user"
)

check_group_definition(
  node['cluster']['cluster_admin_group'],
  node['cluster']['cluster_admin_group_id']
)

if node['cluster']['node_type'] == 'HeadNode' && node['cluster']['scheduler'] == 'slurm'
  check_path_permissions(
    "/opt/slurm/etc/pcluster/.slurm_plugin",
    node['cluster']['cluster_admin_user'],
    node['cluster']['cluster_admin_group'],
    "drwxr-xr-x"
  )
end

###################
# Slurm sudoers
###################
if node['cluster']['scheduler'] == 'slurm'
  [node['cluster']['cluster_admin_user'], "slurm"].each do |user|
    check_sudoers_permissions(
      "/etc/sudoers.d/99-parallelcluster-slurm",
      user, "root", "SLURM_COMMANDS", "/opt/slurm/bin/scontrol"
    )
  end
end
