# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: nvidia_driver
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

return unless node['cluster']['nvidia']['enabled'] == 'yes' || node['cluster']['nvidia']['enabled'] == true

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

# Amazon linux 2 with Kernel 5 need to set CC to /usr/bin/gcc10-gcc using dkms override
if platform?('amazon') && node['kernel']['release'].split('.')[0].to_i == 5
  package "gcc10" do
    retries 10
    retry_delay 5
  end
  cookbook_file 'dkms/nvidia.conf' do
    source 'dkms/nvidia.conf'
    path '/etc/dkms/nvidia.conf'
    owner 'root'
    group 'root'
    mode '0644'
  end
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


