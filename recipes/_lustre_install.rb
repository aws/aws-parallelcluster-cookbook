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

# Install only on Centos 7.6 and 7.5
if node['platform'] == 'centos' && (5..6).cover?(node['platform_version'].split('.')[1].to_i)
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

  kernel_module 'lnet'
elsif node['platform'] == 'centos' && node['platform_version'].split('.')[1].to_i == 7

  # Install build dependencies
  package %w[libselinux-devel libyaml-devel rpm-build gcc git make] do
    retries 3
    retry_delay 5
  end

  # grab lustre source
  bash "clone github repo" do
    cwd node['cfncluster']['sources_dir']
    code <<-LUSTRECLONE
      set -e
      git clone git://git.whamcloud.com/fs/lustre-release.git --depth 2 -b 2.10.8
    LUSTRECLONE
    not_if { ::Dir.exist?("#{node['cfncluster']['sources_dir']}/lustre-release") }
  end

  # Make RPMS
  bash "make rpms" do
    cwd "#{node['cfncluster']['sources_dir']}/lustre-release"
    code <<-LUSTREBUILD
      set -e
      sh ./autogen.sh
      ./configure --disable-server --with-o2ib=no
      make rpms
    LUSTREBUILD
    not_if { ::File.exist?("#{node['cfncluster']['sources_dir']}/lustre-release/kmod-lustre-client-2.10.8-1.el7.x86_64.rpm") }
  end

  # Install lustre mount drivers
  yum_package 'lustre_kmod' do
    source "#{node['cfncluster']['sources_dir']}/lustre-release/kmod-lustre-client-2.10.8-1.el7.x86_64.rpm"
  end

  # Install lustre mount drivers
  yum_package 'lustre_client' do
    source "#{node['cfncluster']['sources_dir']}/lustre-release/lustre-client-2.10.8-1.el7.x86_64.rpm"
  end

  kernel_module 'lnet'
elsif node['platform'] == 'centos'
  Chef::Log.warn("Unsupported version of Centos, #{node['platform_version']}, supported versions are 7.5, 7.6 and 7.7")
elsif node['platform'] == 'amazon'

  # Install lustre client module
  package 'lustre-client' do
    retries 3
    retry_delay 5
  end

  kernel_module 'lnet'
end
