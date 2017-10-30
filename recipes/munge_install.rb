#
# Cookbook Name:: cfncluster
# Recipe:: munge_install
#
# Copyright 2013-2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

include_recipe 'cfncluster::base_install'

munge_tarball = "#{node['cfncluster']['sources_dir']}/munge-#{node['cfncluster']['munge']['munge_version']}.tar.gz"

# Get munge tarball
remote_file munge_tarball do
  source node['cfncluster']['munge']['munge_url']
  mode '0644'
  # TODO: Add version or checksum checks
  not_if { ::File.exist?(munge_tarball) }
end

# Set libdir based on platform, default is /usr/lib64 for RHEL/CentOS/Alinux
munge_libdir = '/usr/lib64'
munge_libdir = '/usr/lib' if node['platform_family'] == 'debian'

# Install munge
bash 'make install' do
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-MUNGE
    tar xf #{munge_tarball}
    cd munge-munge-#{node['cfncluster']['munge']['munge_version']}
    ./bootstrap
    ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --libdir=#{munge_libdir}
    CORES=$(grep processor /proc/cpuinfo | wc -l)
    make -j $CORES
    make install
  MUNGE
  # TODO: Fix, so it works for upgrade
  creates '/usr/bin/munge'
  not_if "/usr/sbin/munged --version | grep -q munge-#{node['cfncluster']['munge']['munge_version']}"
end

# Updated munge init script for Amazon Linux
cookbook_file "munge-init" do
  path '/etc/init.d/munge'
  user 'root'
  group 'root'
  mode '0755'
end

# Make sure the munge user exists
user 'munge' do
  supports manage_home: false
  comment 'munge user'
  system true
  shell '/sbin/nologin'
end

# Create required directories for munge
dirs = ["/var/log/munge", "/etc/munge", "/var/run/munge"]
dirs.each do |dir|
  directory dir do
    action :create
    owner "munge"
  end
end
