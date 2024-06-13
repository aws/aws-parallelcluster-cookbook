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

property :nvidia_driver_version, String

tmp_nvidia_run = '/tmp/nvidia.run'

action :setup do
  return unless nvidia_driver_enabled?
  return if on_docker?

  # Share nvidia driver version with InSpec tests
  node.default['cluster']['nvidia']['driver_version'] = _nvidia_driver_version
  node_attributes "Save Nvidia driver version for Inspec tests"

  remote_file tmp_nvidia_run do
    source nvidia_driver_url
    mode '0755'
    retries 3
    retry_delay 5
    not_if { ::File.exist?('/usr/bin/nvidia-smi') }
  end

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

  # Install driver
  # TODO remove --no-cc-version-check when we can update ubuntu 22 images
  bash 'nvidia.run advanced' do
    user 'root'
    group 'root'
    cwd '/tmp'
    code <<-NVIDIA
      set -e
      #{compiler_path} ./nvidia.run --silent --dkms --disable-nouveau --no-cc-version-check -m=#{nvidia_kernel_module}
      rm -f /tmp/nvidia.run
    NVIDIA
    creates '/usr/bin/nvidia-smi'
  end

  execute 'initramfs to remove nouveau' do
    command 'update-initramfs -u'
    only_if 'lsinitramfs /boot/initrd.img-$(uname -r) | grep nouveau'
  end if rebuild_initramfs?
end

def _nvidia_driver_version
  nvidia_driver_version || node['cluster']['nvidia']['driver_version']
end

def nvidia_driver_url
  "https://us.download.nvidia.com/tesla/#{_nvidia_driver_version}/NVIDIA-Linux-#{nvidia_arch}-#{_nvidia_driver_version}.run"
end

def nvidia_driver_enabled?
  nvidia_enabled?
end

def nvidia_arch
  arm_instance? ? 'aarch64' : 'x86_64'
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

def nvidia_kernel_module
  if ['false', 'no', false].include?(node['cluster']['nvidia']['kernel_open'])
    "kernel"
  else
    "kernel-open"
  end
end
