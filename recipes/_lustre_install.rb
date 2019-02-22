#
# Cookbook Name:: aws-parallelcluster
# Recipe:: lustre_install
#
# Copyright 2013-2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

case node['platform']
when "centos"

  lustre_kmod_rpm = "#{node['cfncluster']['sources_dir']}/kmod-lustre-client-#{node['cfncluster']['lustre']['version']}.x86_64.rpm"
  lustre_client_rpm = "#{node['cfncluster']['sources_dir']}/lustre-client-#{node['cfncluster']['lustre']['version']}.x86_64.rpm"

  # Get Lustre Kernel Module RPM
  remote_file lustre_kmod_rpm do
    source node['cfncluster']['lustre']['kmod_url']
    mode '0644'
    retries 3
    retry_delay 5
    not_if { ::File.exist?(lustre_kmod_rpm) }
  end

  # Get Lustre Client RPM
  remote_file lustre_client_rpm do
    source node['cfncluster']['lustre']['client_url']
    mode '0644'
    retries 3
    retry_delay 5
    not_if { ::File.exist?(lustre_client_rpm) }
  end

  # Install lustre mount drivers
  yum_package 'lustre_kmod' do
    source lustre_kmod_rpm
  end

  # Install lustre mount drivers
  yum_package 'lustre_client' do
    source lustre_client_rpm
  end

when "ubuntu"
  lustre_client_modules = "#{node['cfncluster']['sources_dir']}/lustre-client-modules-4.4.0-131-generic_#{node['cfncluster']['lustre']['version']}_amd64.deb"
  lustre_utils = "#{node['cfncluster']['sources_dir']}/lustre-utils_#{node['cfncluster']['lustre']['version']}_amd64.deb"

  # Get Lustre Client Module
  remote_file lustre_client_modules do
    source node['cfncluster']['lustre']['client']
    mode '0644'
    retries 3
    retry_delay 5
    not_if { ::File.exist?(lustre_client_modules) }
  end

  # Get Lustre Client Utils
  remote_file lustre_utils do
    source node['cfncluster']['lustre']['utils']
    mode '0644'
    retries 3
    retry_delay 5
    not_if { ::File.exist?(lustre_utils) }
  end

  # Install lustre mount drivers
  package 'lustre_client_modules' do
    source lustre_client_modules
  end

  # Install lustre mount drivers
  package 'lustre_utils' do
    source lustre_utils
  end
end
