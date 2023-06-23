# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: config_compute
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

# TODO: rename, find a better name that include login nodes
setup_munge_compute_node

# TODO: double-check if it may be useful in Login Nodes
#  Create directory configured as SlurmdSpoolDir
# directory '/var/spool/slurmd' do
#   user node['cluster']['slurm']['user']
#   group node['cluster']['slurm']['group']
#   mode '0700'
# end

# Mount /opt/slurm over NFS
mount "#{node['cluster']['slurm']['install_dir']}" do
  device(lazy { "#{node['cluster']['head_node_private_ip']}:#{node['cluster']['slurm']['install_dir']}" })
  fstype "nfs"
  options node['cluster']['nfs']['hard_mount_options']
  action %i(mount enable)
  retries 10
  retry_delay 6
end
