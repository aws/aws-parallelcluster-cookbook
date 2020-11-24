# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: _nvidia_install
#
# Copyright 2013-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

if node['cfncluster']['nvidia']['enabled'] == 'yes' || node['cfncluster']['nvidia']['enabled'] == true

  # Get NVIDIA run file
  nvidia_tmp_runfile = "/tmp/nvidia.run"
  remote_file nvidia_tmp_runfile do
    source node['cfncluster']['nvidia']['driver_url']
    mode '0755'
    retries 3
    retry_delay 5
    not_if { ::File.exist?('/usr/bin/nvidia-smi') }
  end

  # Install NVIDIA driver
  bash 'nvidia.run advanced' do
    user 'root'
    group 'root'
    cwd '/tmp'
    code <<-NVIDIA
      set -e
      ./nvidia.run --silent --dkms
      rm -f /tmp/nvidia.run
    NVIDIA
    creates '/usr/bin/nvidia-smi'
  end

  # Get CUDA run file
  cuda_tmp_runfile = "/tmp/cuda.run"
  remote_file cuda_tmp_runfile do
    source node['cfncluster']['nvidia']['cuda_url']
    mode '0755'
    retries 3
    retry_delay 5
    not_if { ::File.exist?("/usr/local/cuda-#{node['cfncluster']['nvidia']['cuda_version']}") }
  end

  # Install CUDA driver
  bash 'cuda.run advanced' do
    user 'root'
    group 'root'
    cwd '/tmp'
    code <<-CUDA
      set -e
      ./cuda.run --silent --toolkit
      rm -f /tmp/cuda.run
    CUDA
    creates "/usr/local/cuda-#{node['cfncluster']['nvidia']['cuda_version']}"
  end

  cookbook_file 'blacklist-nouveau.conf' do
    path '/etc/modprobe.d/blacklist-nouveau.conf'
    owner 'root'
    group 'root'
    mode '0644'
  end

  if node['platform'] == 'ubuntu'
    execute 'initramfs to remove nouveau' do
      command 'update-initramfs -u'
      only_if 'lsinitramfs /boot/initrd.img-$(uname -r) | grep nouveau'
    end
  end

  # Install NVIDIA Fabric Manager (not available on alinux)
  unless node['cfncluster']['cfn_base_os'] == 'alinux'
    add_package_repository(
      "nvidia-fm-repo",
      node['cfncluster']['nvidia']['fabricmanager']['repository_uri'],
      "#{node['cfncluster']['nvidia']['fabricmanager']['repository_uri']}/#{node['cfncluster']['nvidia']['fabricmanager']['repository_key']}",
      "/"
    )

    package node['cfncluster']['nvidia']['fabricmanager']['package'] do
      version node['cfncluster']['nvidia']['fabricmanager']['version']
    end

    remove_package_repository("nvidia-fm-repo")
  end

end
