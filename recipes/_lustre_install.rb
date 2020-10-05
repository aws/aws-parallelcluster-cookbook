# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: _lustre_install
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

return unless node['conditions']['lustre_supported']

if node['platform'] == 'centos' && %w[7.5 7.6].include?(node['platform_version'].to_f)
  # Centos 7.6 and 7.5

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
  package 'lustre_kmod' do
    source lustre_kmod_rpm
  end

  # Install lustre mount drivers
  package 'lustre_client' do
    source lustre_client_rpm
  end

  kernel_module 'lnet'

elsif node['platform'] == 'centos' && node['platform_version'].to_f >= 7.7
  # Centos 8 and >= 7.7

  # add fsx lustre repository
  yum_repository "aws-fsx" do
    description "AWS FSx Packages - $basearch"
    baseurl node['cfncluster']['lustre']['base_url']
    gpgkey node['cfncluster']['lustre']['public_key']
    retries 3
    retry_delay 5
  end

  package %w[kmod-lustre-client lustre-client] do
    retries 3
    retry_delay 5
  end

  kernel_module 'lnet'

elsif node['platform'] == 'centos'
  # Centos 6
  Chef::Log.warn("Unsupported version of Centos, #{node['platform_version']}, supported versions are >= 7.5")

elsif node['platform'] == 'ubuntu'

  apt_repository 'fsxlustreclientrepo' do
    uri          node['cfncluster']['lustre']['base_url']
    components   ['main']
    distribution node['lsb']['codename']
    key          node['cfncluster']['lustre']['public_key']
    retries 3
    retry_delay 5
  end

  apt_update

  package "lustre-client-modules-#{node['kernel']['release']}" do
    retries 3
    retry_delay 5
  end

  package "lustre-client-modules-aws" do
    retries 3
    retry_delay 5
  end

  kernel_module 'lnet'

elsif node['platform'] == 'amazon' && node['platform_version'].to_i == 2

  alinux_extras_topic 'lustre2.10'

elsif node['platform'] == 'amazon' # Amazon Linux 1

  # Install lustre client module
  package 'lustre-client' do
    retries 3
    retry_delay 5
  end

  kernel_module 'lnet'
end
