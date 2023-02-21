# frozen_string_literal: true

#
# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

# This works for Centos 7.6 and 7.5
action :install_lustre_old_centos do
  lustre_kmod_rpm = "#{node['cluster']['sources_dir']}/kmod-lustre-client-#{node['cluster']['lustre']['version']}.x86_64.rpm"
  lustre_client_rpm = "#{node['cluster']['sources_dir']}/lustre-client-#{node['cluster']['lustre']['version']}.x86_64.rpm"

  # Get Lustre Kernel Module RPM
  remote_file lustre_kmod_rpm do
    source node['cluster']['lustre']['kmod_url']
    mode '0644'
    retries 3
    retry_delay 5
    not_if { ::File.exist?(lustre_kmod_rpm) }
  end

  # Get Lustre Client RPM
  remote_file lustre_client_rpm do
    source node['cluster']['lustre']['client_url']
    mode '0644'
    retries 3
    retry_delay 5
    not_if { ::File.exist?(lustre_client_rpm) }
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
end
