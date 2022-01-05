# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: nvidia
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

if node['cluster']['nvidia']['enabled'] == 'yes' || node['cluster']['nvidia']['enabled'] == true

  # Get NVIDIA run file
  nvidia_tmp_runfile = "/tmp/nvidia.run"
  remote_file nvidia_tmp_runfile do
    source node['cluster']['nvidia']['driver_url']
    mode '0755'
    retries 3
    retry_delay 5
    not_if { ::File.exist?('/usr/bin/nvidia-smi') }
  end

  # Make sure nouveau kernel module is unloaded, otherwise installation of NVIDIA driver fails
  kernel_module 'nouveau' do
    action :uninstall
  end

  # Install NVIDIA driver
  bash 'nvidia.run advanced' do
    user 'root'
    group 'root'
    cwd '/tmp'
    code <<-NVIDIA
      set -e
      ./nvidia.run --silent --dkms --disable-nouveau
      rm -f /tmp/nvidia.run
    NVIDIA
    creates '/usr/bin/nvidia-smi'
  end

  # Get CUDA run file
  cuda_tmp_runfile = "/tmp/cuda.run"
  remote_file cuda_tmp_runfile do
    source node['cluster']['nvidia']['cuda_url']
    mode '0755'
    retries 3
    retry_delay 5
    not_if { ::File.exist?("/usr/local/cuda-#{node['cluster']['nvidia']['cuda_version']}") }
  end

  # Install CUDA driver
  bash 'cuda.run advanced' do
    user 'root'
    group 'root'
    cwd '/tmp'
    code <<-CUDA
      set -e
      ./cuda.run --silent --toolkit --samples
      rm -f /tmp/cuda.run
    CUDA
    creates "/usr/local/cuda-#{node['cluster']['nvidia']['cuda_version']}"
  end

  cookbook_file 'blacklist-nouveau.conf' do
    source 'nvidia/blacklist-nouveau.conf'
    path '/etc/modprobe.d/blacklist-nouveau.conf'
    owner 'root'
    group 'root'
    mode '0644'
  end

  if platform?('ubuntu')
    execute 'initramfs to remove nouveau' do
      command 'update-initramfs -u'
      only_if 'lsinitramfs /boot/initrd.img-$(uname -r) | grep nouveau'
    end
  end

  # NVIDIA Fabric Manager not present on ARM
  unless arm_instance?
    # Install NVIDIA Fabric Manager
    repo_domain = "com"
    repo_domain = "cn" if node['cluster']['region'].start_with?("cn-")
    repo_uri = node['cluster']['nvidia']['fabricmanager']['repository_uri'].gsub('_domain_', repo_domain)
    add_package_repository(
      "nvidia-fm-repo",
      repo_uri,
      "#{repo_uri}/#{node['cluster']['nvidia']['fabricmanager']['repository_key']}",
      "/"
    )

    if platform?('ubuntu')
      # For ubuntu, CINC17 apt-package resources need full versions for `version`
      execute "install_fabricmanager_for_ubuntu" do
        command "apt -y install #{node['cluster']['nvidia']['fabricmanager']['package']}=#{node['cluster']['nvidia']['fabricmanager']['version']} "\
                "&& apt-mark hold #{node['cluster']['nvidia']['fabricmanager']['package']}"
        retries 3
        retry_delay 5
      end
    else
      package node['cluster']['nvidia']['fabricmanager']['package'] do
        version node['cluster']['nvidia']['fabricmanager']['version']
        action %i(install lock)
      end
    end

    remove_package_repository("nvidia-fm-repo")
  end
end
