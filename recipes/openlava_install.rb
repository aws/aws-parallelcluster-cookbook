#
# Cookbook Name:: cfncluster
# Recipe:: openlava_install
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

openlava_tarball = "#{node['cfncluster']['sources_dir']}/openlava-#{node['cfncluster']['openlava']['version']}.tar.gz"

# Get Openlava tarball
remote_file openlava_tarball do
  source node['cfncluster']['openlava']['url']
  mode '0644'
  # TODO: Add version or checksum checks
  not_if { ::File.exist?(openlava_tarball) }
end

# Install Openlava
bash 'make install' do
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-EOF
    tar xf #{openlava_tarball}
    cd openlava-#{node['cfncluster']['openlava']['version']}
    ./bootstrap.sh
    ./configure --prefix=/opt/openlava
    CORES=$(grep processor /proc/cpuinfo | wc -l)
    make -j $CORES
    make install
  EOF
  # TODO: Fix, so it works for upgrade
  creates '/opt/openlava/bin/lsid'
end

# Install Openlava config files
cfiles = ["lsf.conf", "lsb.hosts", "lsb.params", "lsb.queues", "lsb.users", "lsf.cluster.openlava", "lsf.shared", "lsf.task", "openlava.csh", "openlava.setup", "openlava.sh"]
cfiles.each do |cfile|
  bash "copy #{cfile}" do
    user 'root'
    group 'root'
    cwd Chef::Config[:file_cache_path]
    code <<-EOF
      cd openlava-#{node['cfncluster']['openlava']['version']}/config
      cp #{cfile} /opt/openlava/etc
    EOF
    creates "/opt/openlava/etc/#{cfile}"
  end
end

# Setup openlava user
user "openlava" do
  supports manage_home: true
  comment 'openlava user'
  home "/home/openlava"
  system true
  shell '/bin/bash'
end

# Set ownership of /opt/openlava to openlava user
execute 'chown' do
  command 'chown -R openlava:openlava /opt/openlava'
end

# Install openlava-python bindings
python_package 'cython'

# Copy required licensing files
directory "#{node['cfncluster']['license_dir']}/openlava"

bash 'copy license stuff' do
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-EOF
    cd openlava-#{node['cfncluster']['openlava']['version']}
    cp -v COPYING #{node['cfncluster']['license_dir']}/openlava/COPYING
    cp -v README #{node['cfncluster']['license_dir']}/openlava/README
  EOF
  # TODO: Fix, so it works for upgrade
  creates "#{node['cfncluster']['license_dir']}/openlava/README"
end
