# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: nvidia
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

fabric_manager 'Configure fabric manager' do
  action :configure
end
gdrcopy 'Configure gdrcopy' do
  action :configure
end

if graphic_instance? && nvidia_installed?
  # Load kernel module Nvidia-uvm
  kernel_module 'nvidia-uvm' do
    action :load
  end
  # Make sure kernel module Nvidia-uvm is loaded at instance boot time
  cookbook_file 'nvidia.conf' do
    source 'nvidia/nvidia.conf'
    path '/etc/modules-load.d/nvidia.conf'
    owner 'root'
    group 'root'
    mode '0644'
  end

  # Install ParallelCluster nvidia service.
  # The service ensures the creation of the block devices /dev/nvidia0 after reboot and it is needed by the slurmd service
  # cookbooks/aws-parallelcluster-slurm/templates/default/slurm/compute/slurmd_nvidia_persistenced.conf.erb
  #
  # The service starts the nvidia-persistenced or run nvidia-smi to avoid race condition with other services
  template '/etc/systemd/system/parallelcluster_nvidia.service' do
    source 'nvidia/parallelcluster_nvidia_service.erb'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
    variables(is_nvidia_persistenced_running: is_process_running('nvidia-persistenced'))
  end

  service "parallelcluster_nvidia" do
    supports restart: false
    action %i(enable start)
  end
end
