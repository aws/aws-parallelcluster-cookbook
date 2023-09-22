# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: config_compute
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

setup_munge_compute_node

# Create directory configured as SlurmdSpoolDir
directory '/var/spool/slurmd' do
  user node['cluster']['slurm']['user']
  group node['cluster']['slurm']['group']
  mode '0700'
end

# Check to see if is GPU instance with Nvidia installed
Chef::Log.warn("GPU instance but no Nvidia drivers found") if graphic_instance? && !nvidia_installed?

# Run nvidia-smi triggers loading of the kernel module and creation of the device files
# This should become useless with the configuration of the systemd dependency between
# nvidia-persistenced and slurmd
if graphic_instance? && nvidia_installed?
  execute "run_nvidiasmi" do
    command 'nvidia-smi'
  end
end

include_recipe 'aws-parallelcluster-slurm::config_slurmd_systemd_service'

if node['cluster']['enable_nss_slurm'] == 'true'
  nsswitch_path = '/etc/nsswitch.conf'
  bash 'Add Slurm to nsswitch.conf' do
    code <<-NSSWITCH
      sed -i 's/^passwd: */&slurm /' #{nsswitch_path}
      sed -i 's/^group: */&slurm /' #{nsswitch_path}
    NSSWITCH
  end

  file '/etc/nss_slurm.conf' do
    content("NodeName=#{slurm_nodename}")
    mode '0644'
    owner 'root'
    group 'root'
  end
end
