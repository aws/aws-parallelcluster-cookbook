# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: compute_slurm_config
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

setup_munge_compute_node

# Create directory configured as SlurmdSpoolDir
directory '/var/spool/slurmd' do
  user 'slurm'
  group 'slurm'
  mode '0700'
end

# Mount /opt/slurm over NFS
# Computemgtd config is under /opt/slurm/etc/pcluster; all compute nodes share a config
mount '/opt/slurm' do
  device(lazy { "#{node['cfncluster']['cfn_master_private_ip']}:/opt/slurm" })
  fstype "nfs"
  options 'hard,intr,noatime,_netdev'
  action %i[mount enable]
  retries 3
  retry_delay 5
end

# Check to see if there is GPU on the instance, only execute run_nvidiasmi if there is GPU
if graphic_instance?
  execute "run_nvidiasmi" do
    command 'nvidia-smi'
  end
end

cookbook_file '/etc/systemd/system/slurmd.service' do
  source 'slurmd.service'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
  only_if { node['init_package'] == 'systemd' }
end
