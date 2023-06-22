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

# Load kernel module Nvidia-uvm
kernel_module 'nvidia-uvm' do
  only_if { graphic_instance? && nvidia_installed? }
  action :load
end

# Make sure kernel module Nvidia-uvm is loaded at instance boot time
cookbook_file 'nvidia.conf' do
  only_if { graphic_instance? && nvidia_installed? }
  source 'nvidia/nvidia.conf'
  path '/etc/modules-load.d/nvidia.conf'
  owner 'root'
  group 'root'
  mode '0644'
end

# Install nvidia_persistenced. See https://download.nvidia.com/XFree86/Linux-x86_64/396.51/README/nvidia-persistenced.html
bash 'Install nvidia_persistenced' do
  only_if { graphic_instance? && nvidia_installed? }
  cwd '/usr/share/doc/NVIDIA_GLX-1.0/samples'
  user 'root'
  group 'root'
  code <<-NVIDIA
    tar -xf nvidia-persistenced-init.tar.bz2
    ./nvidia-persistenced-init/install.sh
  NVIDIA
end
