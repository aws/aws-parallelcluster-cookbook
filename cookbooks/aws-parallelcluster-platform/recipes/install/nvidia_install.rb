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

nvidia_repo 'Add NVIDIA driver local repo' do
  action :add_driver_repo
end

nvidia_driver 'Install Nvidia driver'

nvidia_nvlsm 'Install Nvidia NVLink Subnet Manager'

fabric_manager 'Install Nvidia Fabric Manager'

nvidia_imex 'Install nvidia-imex'

nvidia_repo 'Remove NVIDIA driver local repo' do
  action :remove_driver_repo
end

nvidia_repo 'Add NVIDIA CUDA local repo' do
  action :add_cuda_repo
end

nvidia_cuda 'Install Nvidia CUDA'

nvidia_repo 'Remove NVIDIA CUDA local repo' do
  action :remove_cuda_repo
end

gdrcopy 'Install Nvidia gdrcopy'

nvidia_dcgm 'install Nvidia datacenter-gpu-manager'
