# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-test
# Recipe:: tests_users
#
# Copyright:: 2013-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
    "#{node['cluster']['slurm']['install_dir']}/etc/pcluster/.slurm_plugin",
    node['cluster']['cluster_admin_user'],
    node['cluster']['cluster_admin_group'],
    "drwxr-xr-x"
  )
end

###################
# Slurm user
###################
if node['cluster']['scheduler'] == 'slurm'
  check_user_definition(
    node['cluster']['slurm']['user'],
    node['cluster']['slurm']['user_id'],
    node['cluster']['slurm']['group_id'],
    'slurm user'
  )

  check_group_definition(
    node['cluster']['slurm']['group'],
    node['cluster']['slurm']['group_id']
  )
end

###################
# Munge user
###################
if node['cluster']['scheduler'] == 'slurm'
  check_user_definition(
    node['cluster']['munge']['user'],
    node['cluster']['munge']['user_id'],
    node['cluster']['munge']['group_id'],
    'munge user',
    '/sbin/nologin'
  )

  check_group_definition(
    node['cluster']['munge']['group'],
    node['cluster']['munge']['group_id']
  )
end

###################
# DCV ExtAuth user
###################
if node['conditions']['dcv_supported']
  check_user_definition(
    node['cluster']['dcv']['authenticator']['user'],
    node['cluster']['dcv']['authenticator']['user_id'],
    node['cluster']['dcv']['authenticator']['group_id'],
    'NICE DCV External Authenticator user'
  )

  check_group_definition(
    node['cluster']['dcv']['authenticator']['group'],
    node['cluster']['dcv']['authenticator']['group_id']
  )
end

###################
# Slurm sudoers
###################
if node['cluster']['scheduler'] == 'slurm'
  sudoers_file = "/etc/sudoers.d/99-parallelcluster-slurm"
  cluster_admin_user = node['cluster']['cluster_admin_user']
  cluster_slurm_user = node['cluster']['slurm']['user']
  venv_path = node['cluster']['node_virtualenv_path']

  check_sudoers_permissions(
    sudoers_file,
    cluster_admin_user, "root", "SLURM_COMMANDS",
    "#{node['cluster']['slurm']['install_dir']}/bin/scontrol"
  )

  check_sudoers_permissions(
    sudoers_file,
    cluster_admin_user, "root", "SHUTDOWN",
    "/usr/sbin/shutdown"
  )

  check_sudoers_permissions(
    sudoers_file,
    cluster_slurm_user, cluster_admin_user, "SLURM_HOOKS_COMMANDS",
    "#{venv_path}/bin/slurm_suspend, #{venv_path}/bin/slurm_resume, #{venv_path}/bin/slurm_fleet_status_manager"
  )
end
