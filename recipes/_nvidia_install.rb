#
# Cookbook Name:: cfncluster
# Recipe:: _nvidia_install
#
# Copyright 2013-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/asl/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Only run if node['cfncluster']['nvidia']['enabled'] = true
if node['cfncluster']['nvidia']['enabled'] == true

  case node['platform_family']
  when 'rhel'
    yum_package node['cfncluster']['kernel_devel_pkg']['name'] do
      version node['cfncluster']['kernel_devel_pkg']['version']
      allow_downgrade true
    end
  when 'debian'
    package = "#{node['cfncluster']['kernel_devel_pkg']['name']}-#{node['cfncluster']['kernel_devel_pkg']['version']}"
    apt_package package
  end

  # Get NVIDIA run file
  nvidia_tmp_runfile = "/tmp/nvidia.run"
  remote_file nvidia_tmp_runfile do
    source node['cfncluster']['nvidia']['driver_url']
    mode '0755'
    not_if { ::File.exist?(nvidia_tmp_runfile) }
  end

  # Install NVIDIA driver
  bash 'nvidia.run advanced' do
    user 'root'
    group 'root'
    cwd '/tmp'
    code <<-EOF
    ./nvidia.run --silent --no-network --dkms
    EOF
    creates '/usr/bin/nvidia-smi'
  end

  # Get CUDA run file
  cuda_tmp_runfile = "/tmp/cuda.run"
  remote_file cuda_tmp_runfile do
    source node['cfncluster']['nvidia']['cuda_url']
    mode '0755'
    not_if { ::File.exist?(cuda_tmp_runfile) }
  end

  # Install CUDA driver
  bash 'cuda.run advanced' do
    user 'root'
    group 'root'
    cwd '/tmp'
    code <<-EOF
    ./cuda.run --silent --toolkit
    EOF
    creates '/usr/local/cuda-7.5'
  end
end
