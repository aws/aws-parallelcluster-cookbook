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

# Create systemd service file for slurmd
template '/etc/systemd/system/slurmd.service' do
  source 'slurm/compute/slurmd.service.erb'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

# Add systemd dependency between slurmd and nvidia-persistenced for NVIDIA GPU nodes
if graphic_instance? && nvidia_installed?
  directory '/etc/systemd/system/slurmd.service.d' do
    user 'root'
    group 'root'
    mode '0755'
  end
  template '/etc/systemd/system/slurmd.service.d/slurmd_nvidia_persistenced.conf' do
    source 'slurm/compute/slurmd_nvidia_persistenced.conf.erb'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
  end
end
