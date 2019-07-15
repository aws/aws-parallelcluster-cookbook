#
# Cookbook Name:: aws-parallelcluster
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
when 'rhel', 'amazon'
  include_recipe 'yum'
  include_recipe "yum-epel" if node['platform_version'].to_i < 7

  unless node['platform_version'].to_i < 7
    execute 'yum-config-manager_skip_if_unavail' do
      command "yum-config-manager --setopt=\*.skip_if_unavailable=1 --save"
    end
  end

  if node['platform'] == 'redhat'
    execute 'yum-config-manager-rhel' do
      command "yum-config-manager --enable #{node['cfncluster']['rhel']['extra_repo']}"
    end
  end
when 'debian'
  include_recipe 'apt'
end

# Setup directories
directory '/etc/parallelcluster'
directory node['cfncluster']['base_dir']
directory node['cfncluster']['sources_dir']
directory node['cfncluster']['scripts_dir']
directory node['cfncluster']['license_dir']
directory node['cfncluster']['virtualenv']

build_essential
include_recipe "aws-parallelcluster::_setup_python"

# Install awscli outside of virtualenv
python_package "awscli"

# Install lots of packages
node['cfncluster']['base_packages'].each do |p|
  package p do
    retries 3
    retry_delay 5
  end
end

# Manage SSH via Chef
include_recipe "openssh"

# Disable selinux
selinux_state "SELinux Disabled" do
  action :disabled
  only_if 'which getenforce'
end

# Install LICENSE README
cookbook_file 'AWS-ParallelCluster-License-README.txt' do
  path "#{node['cfncluster']['license_dir']}/AWS-ParallelCluster-License-README.txt"
  user 'root'
  group 'root'
  mode '0644'
end

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

include_recipe 'aws-parallelcluster::_ec2_udev_rules'

# Install ec2-metadata script
remote_file '/usr/bin/ec2-metadata' do
  source 'http://s3.amazonaws.com/ec2metadata/ec2-metadata'
  user 'root'
  group 'root'
  mode '0755'
  retries 3
  retry_delay 5
end

# Check whether install a custom aws-parallelcluster-node package or the standard one
if !node['cfncluster']['custom_node_package'].nil? && !node['cfncluster']['custom_node_package'].empty?
  # Install custom aws-parallelcluster-node package
  bash "install aws-parallelcluster-node" do
    cwd Chef::Config[:file_cache_path]
    code <<-NODE
      [[ ":$PATH:" != *":/usr/local/bin:"* ]] && PATH="/usr/local/bin:${PATH}"
      echo "PATH is $PATH"
      source /tmp/proxy.sh
      source #{node['cfncluster']['virtualenv']}/bin/activate
      pip uninstall --yes aws-parallelcluster-node
      curl --retry 3 -v -L -o aws-parallelcluster-node.tgz #{node['cfncluster']['custom_node_package']}
      tar -xzf aws-parallelcluster-node.tgz
      cd *aws-parallelcluster-node-*
      pip install .
      deactivate
    NODE
  end
else
  pyenv_pip 'aws-parallelcluster-node' do
    version node['cfncluster']['cfncluster-node-version']
    virtualenv node['cfncluster']['virtualenv']
  end
end

# Put supervisord config in place
cookbook_file "supervisord.conf" do
  path "/etc/supervisord.conf"
  owner "root"
  group "root"
  mode "0644"
end

# Put init script in place
template "supervisord-init" do
  source 'supervisord-init.erb'
  path "/etc/init.d/supervisord"
  owner "root"
  group "root"
  mode "0755"
end

if (node['platform'] == 'ubuntu' && node['platform_version'] == "14.04") || (node['platform_family'] == 'rhel' && node['platform_version'].to_i < 7)
  # Install jq for manipulating json files
  cookbook_file "jq-1.4" do
    path "/usr/local/bin/jq"
    owner "root"
    group "root"
    mode "0755"
  end
end

# AMI cleanup script
cookbook_file "ami_cleanup.sh" do
  path '/usr/local/sbin/ami_cleanup.sh'
  owner "root"
  group "root"
  mode "0755"
end

# Install Ganglia
include_recipe "aws-parallelcluster::_ganglia_install"

# Install NVIDIA and CUDA
include_recipe "aws-parallelcluster::_nvidia_install"

# Install FSx options
include_recipe "aws-parallelcluster::_lustre_install"

# Install EFA
if (node['platform'] == 'centos' && node['platform_version'].to_i >= 7) || node['platform'] == 'amazon' || (node['platform'] == 'ubuntu' && node['platform_version'] == "16.04")
  unless node['cfncluster']['cfn_region'].start_with?("cn-")
    include_recipe "aws-parallelcluster::_efa_install"
  else
    case node['platform_family']
      when 'rhel', 'amazon'
        package %w[openmpi-devel openmpi]
      when 'debian'
        package "libopenmpi-dev"
    end
  end
end
