#
# Cookbook Name:: cfncluster
# Recipe:: torque_install
#
# Copyright 2013-2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/asl/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

include_recipe 'cfncluster::base_install'
include_recipe 'cfncluster::munge_install'

torque_tarball = "#{node['cfncluster']['sources_dir']}/torque-#{node['cfncluster']['torque']['version']}.tar.gz"

# Install packages required to build torque
node['cfncluster']['torque_packages'].each do |p|
  package p
end

# Get Torque tarball
remote_file torque_tarball do
  source node['cfncluster']['torque']['url']
  mode '0644'
  # TODO: Add version or checksum checks
  not_if { ::File.exists?(torque_tarball) }
end

# Install Torque
bash 'make install' do
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-EOF
    tar xf #{torque_tarball}
    cd torque-#{node['cfncluster']['torque']['version']}
    ./autogen.sh
    ./configure --prefix=/opt/torque --enable-munge-auth
    CORES=$(grep processor /proc/cpuinfo | wc -l)
    make -j $CORES
    make install
    cp -vpR contrib /opt/torque
  EOF
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

# Modified torque.setup
cookbook_file 'torque.setup' do
  path '/opt/torque/bin/torque.setup'
  user 'root'
  group 'root'
  mode '0755'
end  
