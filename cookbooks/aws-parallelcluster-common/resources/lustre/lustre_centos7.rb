# frozen_string_literal: true

#
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
# Default resource implementation
provides :lustre, platform: 'centos' do |node|
  node['platform_version'].to_i == 7
end
unified_mode true

use 'partial/_install_lustre_centos_redhat'
use 'partial/_mount_unmount'

lustre_version_hash = {
  '7.6' => "2.10.8",
  '7.5' => "2.10.5",
}

client_url_hash = {
  '7.6' => "https://downloads.whamcloud.com/public/lustre/lustre-2.10.8/el7/client/RPMS/x86_64/lustre-client-2.10.8-1.el7.x86_64.rpm",
  '7.5' => "https://downloads.whamcloud.com/public/lustre/lustre-2.10.5/el7.5.1804/client/RPMS/x86_64/lustre-client-2.10.5-1.el7.x86_64.rpm",
}

kmod_url_hash = {
  '7.6' => "https://downloads.whamcloud.com/public/lustre/lustre-2.10.8/el7/client/RPMS/x86_64/kmod-lustre-client-2.10.8-1.el7.x86_64.rpm",
  '7.5' => "https://downloads.whamcloud.com/public/lustre/lustre-2.10.5/el7.5.1804/client/RPMS/x86_64/kmod-lustre-client-2.10.5-1.el7.x86_64.rpm",
}

default_action :setup

action :setup do
  version = node['cluster']['platform_version']
  if %w(7.5 7.6).include?(version)
    lustre_kmod_rpm = "#{node['cluster']['sources_dir']}/kmod-lustre-client-#{lustre_version_hash[version]}.x86_64.rpm"
    lustre_client_rpm = "#{node['cluster']['sources_dir']}/lustre-client-#{lustre_version_hash[version]}.x86_64.rpm"

    # Get Lustre Kernel Module RPM
    remote_file lustre_kmod_rpm do
      source kmod_url_hash[version]
      mode '0644'
      retries 3
      retry_delay 5
      action :create_if_missing
    end

    # Get Lustre Client RPM
    remote_file lustre_client_rpm do
      source client_url_hash[version]
      mode '0644'
      retries 3
      retry_delay 5
      action :create_if_missing
    end

    # Install lustre mount drivers
    package 'lustre_kmod' do
      source lustre_kmod_rpm
    end

    # Install lustre mount drivers
    package 'lustre_client' do
      source lustre_client_rpm
    end

    kernel_module 'lnet'

  elsif version.to_f >= 7.7
    action_install_lustre
  else
    log "Unsupported version of Centos, #{version}, supported versions are >= 7.5" do
      level :warn
    end
  end
end

def base_url_prefix(is_arm)
  is_arm ? 'centos' : 'el'
end

#
# Retrieve RHEL OS minor version from running kernel version
# The OS minor version is retrieved from the patch version of the running kernel
# following the mapping reported here https://access.redhat.com/articles/3078#RHEL7
# Method works for CentOS7 minor version >=7
#
def find_centos_minor_version
  os_minor_version = ''

  # kernel release is in the form 3.10.0-1127.8.2.el7.x86_64
  kernel_patch_version = node['cluster']['kernel_release'].match(/^\d+\.\d+\.\d+-(\d+)\..*$/)
  raise "Unable to retrieve the kernel patch version from #{node['cluster']['kernel_release']}." unless kernel_patch_version

  case node['platform_version'].to_i
  when 7
    os_minor_version = '7' if kernel_patch_version[1] >= '1062'
    os_minor_version = '8' if kernel_patch_version[1] >= '1127'
    os_minor_version = '9' if kernel_patch_version[1] >= '1160'
  else
    raise "CentOS version #{node['platform_version']} not supported."
  end

  os_minor_version
end

action_class do
  def base_url
    "https://fsx-lustre-client-repo.s3.amazonaws.com/#{base_url_prefix(arm_instance?)}/7.#{find_centos_minor_version}/#{node['kernel']['machine']}/"
  end

  def public_key
    "https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-rpm-public-key.asc"
  end
end
