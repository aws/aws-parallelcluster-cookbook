# frozen_string_literal: true
#
# Copyright:: 2013-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

unified_mode true
default_action :setup

property :nvidia_driver_version, String, default: node['cluster']['nvidia']['driver_version']

action :setup do
  return unless nvidia_driver_enabled?
  return if nvidia_driver_installed?
  return if on_docker?

  # Record the configured version that pcluster is about to install so InSpec
  # verifies the right version.
  node.default['cluster']['nvidia']['driver_version'] = new_resource.nvidia_driver_version
  node_attributes "Save Nvidia driver version for Inspec tests"

  # Make sure nouveau kernel module is unloaded, otherwise installation of NVIDIA driver fails
  kernel_module 'nouveau' do
    action :uninstall
  end

  cookbook_file 'blacklist-nouveau.conf' do
    cookbook 'aws-parallelcluster-platform'
    source 'nvidia/blacklist-nouveau.conf'
    path '/etc/modprobe.d/blacklist-nouveau.conf'
    owner 'root'
    group 'root'
    mode '0644'
  end

  if set_compiler?
    package compiler_version do
      retries 10
      retry_delay 5
    end
    package extra_packages do
      only_if { extra_packages.any? }
      retries 10
      retry_delay 5
    end

    template '/etc/dkms/nvidia.conf' do
      source 'nvidia/amazon/dkms/nvidia.conf.erb'
      cookbook 'aws-parallelcluster-platform'
      owner 'root'
      group 'root'
      mode '0644'
      variables(
        compiler_path: compiler_path
      )
    end
  end

  # Load kernel modules in best effort
  kernel_modules_to_load.each do |km|
    execute "Load kernel module if exposed by the kernel: #{km}" do
      command "if modinfo #{km}; then modprobe #{km}; fi"
    end
  end

  # Prepare the system for the driver meta-package install (platform-specific)
  action_prepare_driver_install

  # Install the driver meta-package from the NVIDIA local repo.
  package nvidia_driver_package do
    retries 3
    retry_delay 5
  end

  # Install the extra packages from the NVIDIA local repo alongside the driver.
  extra_driver_packages.each do |pkg|
    package pkg do
      retries 3
      retry_delay 5
    end
  end

  execute 'initramfs to remove nouveau' do
    command 'update-initramfs -u'
    only_if 'lsinitramfs /boot/initrd.img-$(uname -r) | grep nouveau'
  end if rebuild_initramfs?
end

# Whether the open-source kernel modules flavor must be installed.
def nvidia_open_kernel_modules?
  !['false', 'no', false].include?(node['cluster']['nvidia']['kernel_open'])
end

# Driver meta-package installed from the local repo.
# Open kernel modules -> 'nvidia-open', proprietary -> 'cuda-drivers'.
def nvidia_driver_package
  nvidia_open_kernel_modules? ? 'nvidia-open' : 'cuda-drivers'
end

def nvidia_driver_enabled?
  nvidia_enabled?
end

# True if the NVIDIA driver is already installed (e.g. shipped by the base image
# such as the DLAMI). nvidia-smi is the canonical signal of a healthy driver and
# is installed to /usr/bin on all platforms.
def nvidia_driver_installed?
  ::File.exist?('/usr/bin/nvidia-smi')
end

def rebuild_initramfs?
  false
end

def set_compiler?
  false
end

def compiler_path
  ""
end

def kernel_modules_to_load
  %w(drm_client_lib)
end

def extra_driver_packages
  %w(nvidia-xconfig)
end
