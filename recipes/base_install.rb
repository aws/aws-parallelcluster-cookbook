#
# Cookbook Name:: cfncluster
# Recipe:: base_install
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

case node['platform_family']
when 'rhel'
  include_recipe 'yum'
  include_recipe "yum-epel" if node['platform_version'].to_i < 7

  if node['platform'] == 'redhat'
    execute 'yum-config-manager-rhel' do
      command "yum-config-manager --enable #{node['cfncluster']['rhel']['extra_repo']}"
    end
  end
when 'debian'
  include_recipe 'apt'
end
include_recipe "build-essential"
include_recipe "cfncluster::_setup_python"

# Install lots of packages
node['cfncluster']['base_packages'].each do |p|
  package p
end

# Manage SSH via Chef
include_recipe "openssh"

# Disable selinux
selinux_state "SELinux Disabled" do
  action :disabled
  only_if 'which getenforce'
end

# Setup directories
directory '/etc/cfncluster'
directory node['cfncluster']['base_dir']
directory node['cfncluster']['sources_dir']
directory node['cfncluster']['scripts_dir']
directory node['cfncluster']['license_dir']

# Install LICENSE README
cookbook_file 'CfnCluster-License-README.txt' do
  path "#{node['cfncluster']['license_dir']}/CfnCluster-License-README.txt"
  user 'root'
  group 'root'
  mode '0644'
end

# Install AWSCLI
python_package 'awscli'

# TODO: update nfs receipes to stop, disable nfs services
include_recipe "nfs"
service "rpcbind" do
  action %i[start enable]
  supports status: true
  only_if { node['platform_family'] == 'rhel' && node['platform_version'].to_i >= 7 && node['platform'] != 'amazon' }
end
include_recipe "nfs::server"
include_recipe "nfs::server4"

# Put configure-pat.sh onto the host
cookbook_file 'configure-pat.sh' do
  path '/usr/local/sbin/configure-pat.sh'
  user 'root'
  group 'root'
  mode '0744'
end

# Put setup-ephemeral-drives.sh onto the host
cookbook_file 'setup-ephemeral-drives.sh' do
  path '/usr/local/sbin/setup-ephemeral-drives.sh'
  user 'root'
  group 'root'
  mode '0744'
end

include_recipe 'cfncluster::_ec2_udev_rules'

# Install ec2-metadata script
remote_file '/usr/bin/ec2-metadata' do
  source 'http://s3.amazonaws.com/ec2metadata/ec2-metadata'
  user 'root'
  group 'root'
  mode '0755'
end

# Install cfncluster-nodes packages
python_package "cfncluster-node" do
  version node['cfncluster']['cfncluster-node-version']
end

# Supervisord
python_package "supervisor" do
  version node['cfncluster']['supervisor-version']
end

# Put supervisord config in place
cookbook_file "supervisord.conf" do
  path "/etc/supervisord.conf"
  owner "root"
  group "root"
  mode "0644"
end

# Put init script in place
cookbook_file "supervisord-init" do
  path "/etc/init.d/supervisord"
  owner "root"
  group "root"
  mode "0755"
end

# Install jq for manipulating json files
cookbook_file "jq-1.4" do
  path "/usr/local/bin/jq"
  owner "root"
  group "root"
  mode "0755"
end

# AMI cleanup script
cookbook_file "ami_cleanup.sh" do
  path '/usr/local/sbin/ami_cleanup.sh'
  owner "root"
  group "root"
  mode "0755"
end

# Install Ganglia
include_recipe "cfncluster::_ganglia_install"

# Install NVIDIA and CUDA
include_recipe "cfncluster::_nvidia_install"
