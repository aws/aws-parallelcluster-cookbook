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

# Register the NVIDIA local repos (driver and CUDA) up front so that the
# nvidia_driver and nvidia_cuda resources can install their packages from them.
# Versions and URLs default to node attributes and can be overridden there.
nvidia_repo 'Install NVIDIA local repos'

nvidia_driver 'Install Nvidia driver'

nvidia_cuda 'Install Nvidia CUDA'

gdrcopy 'Install Nvidia gdrcopy'

nvidia_nvlsm 'Install Nvidia NVLink Subnet Manager'

fabric_manager 'Install Nvidia Fabric Manager'

nvidia_dcgm 'install Nvidia datacenter-gpu-manager'

nvidia_imex 'Install nvidia-imex'

# Remove the NVIDIA local repos now that all NVIDIA packages have been installed
nvidia_repo 'Remove NVIDIA local repos' do
  action :remove
end
