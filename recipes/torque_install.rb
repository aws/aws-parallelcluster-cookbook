# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: torque_install
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

return if node['conditions']['ami_bootstrapped']

include_recipe 'aws-parallelcluster::base_install'
include_recipe 'aws-parallelcluster::munge_install'

# Get Torque tarball
torque_tarball = "#{node['cfncluster']['sources_dir']}/torque-#{node['cfncluster']['torque']['version']}.tar.gz"
remote_file torque_tarball do
  source node['cfncluster']['torque']['url']
  mode '0644'
  retries 3
  retry_delay 5
  # TODO: Add version or checksum checks
  not_if { ::File.exist?(torque_tarball) }
end

# Define make parameters according to the OS
cxx_flags = value_for_platform(
  'amazon' => { '2' => "-std=c++03" },
  'centos' => { '>=8' => "-std=c++03" },
  'ubuntu' => { '>=18.04' => "-std=c++03 -I#{Chef::Config[:file_cache_path]}/extra_libs/usr/include/x86_64-linux-gnu/" },
  'default' => ""
)
c_flags = value_for_platform(
  'amazon' => { '2' => "-fpermissive" },
  'centos' => { '>=8' => "-fpermissive" },
  'ubuntu' => { '>=18.04' => "-fpermissive" },
  'default' => ""
)
configure_flags = value_for_platform(
  'amazon' => { '2' => "--disable-gcc-warnings" },
  'centos' => { '>=8' => "--disable-gcc-warnings" },
  'ubuntu' => { '>=18.04' => "--disable-gcc-warnings" },
  'default' => ""
)

if node['platform'] == 'ubuntu'
  bash 'prepare_ubuntu' do
    user 'root'
    group 'root'
    cwd Chef::Config[:file_cache_path]
    code <<-TORQUE
      set -e
      # Headers needed for compilation
      # Download all packages matching the pattern 'libicu-dev_55.1-7ubuntu*amd64.deb'
      # recursively (-r), avoiding to ascend to the parent dir (-np)
      # and without creating the hierarchy of directories (-nd)
      wget -r -np -nd http://security.ubuntu.com/ubuntu/pool/main/i/icu/ -A 'libicu-dev_55.1-7ubuntu*amd64.deb'
      dpkg -x libicu-dev_55.1-7ubuntu*amd64.deb extra_libs
    TORQUE
    not_if { ::Dir.exist?("/opt/torque/bin") }
  end
end

# Compile and install Torque
bash 'make install' do
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-TORQUE
    set -e
    export CFLAGS="#{c_flags}"
    export CXXFLAGS="#{cxx_flags}"
    tar xf #{torque_tarball}
    cd torque-#{node['cfncluster']['torque']['version']}
    ./autogen.sh
    ./configure --prefix=/opt/torque --enable-munge-auth --disable-gui #{configure_flags}
    CORES=$(grep processor /proc/cpuinfo | wc -l)
    make -j $CORES
    make install
    cp -vpR contrib /opt/torque
    # Removing torque generated profiles. These will be restored at runtime when scheduler is torque
    rm -f /etc/profile.d/torque.csh /etc/profile.d/torque.sh
  TORQUE
  # Only perform if running version doesn't match desired
  not_if "/opt/torque/bin/pbsnodes --version 2>&1 | grep -q #{node['cfncluster']['torque']['version']}"
  creates "/random/path"
end

directory '/opt/torque/bin/' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
  recursive true
end

directory '/var/spool/torque' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
  recursive true
end

# Copy required licensing files
directory "#{node['cfncluster']['license_dir']}/torque"

bash 'copy license stuff' do
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-TORQUEINSTALL
    set -e
    cd torque-#{node['cfncluster']['torque']['version']}
    cp -v PBS_License.txt #{node['cfncluster']['license_dir']}/torque/PBS_License.txt
    cp -v LICENSE #{node['cfncluster']['license_dir']}/torque/LICENSE
    cp -v README.md #{node['cfncluster']['license_dir']}/torque/README.md
  TORQUEINSTALL
  # TODO: Fix, so it works for upgrade
  creates "#{node['cfncluster']['license_dir']}/torque/README.md"
end
