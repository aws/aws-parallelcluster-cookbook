# frozen_string_literal: true

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

return if node['conditions']['ami_bootstrapped']

case node['platform_family']
when 'rhel', 'amazon'
  include_recipe 'yum'
  if node['platform_family'] == 'amazon' && node['platform_version'].to_i == 2
    alinux_extras_topic 'epel'
  elsif node['platform_version'].to_i < 7
    include_recipe "yum-epel"
  end

  unless node['platform_version'].to_i < 7
    execute 'yum-config-manager_skip_if_unavail' do
      command "yum-config-manager --setopt=\*.skip_if_unavailable=1 --save"
    end
  end
  if node['platform'] == 'centos' && node['platform_version'].to_i == 8
    # Enable PowerTools Repo so *-devel packages can be installed with DNF
    # Enable EPEL repos
    execute 'dnf enable powertools and EPEL repos' do
      command "dnf config-manager --set-enabled PowerTools && dnf install -y epel-release"
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
directory node['cfncluster']['configs_dir']

build_essential
include_recipe "aws-parallelcluster::_setup_python"

# Install lots of packages
package node['cfncluster']['base_packages'] do
  retries 10
  retry_delay 5
end

# In the case of AL2, there are more packages to install via extras
if node['cfncluster']['alinux_extras']
  node['cfncluster']['alinux_extras'].each do |topic|
    alinux_extras_topic topic
  end
end

package "install kernel packages" do
  case node['platform_family']
  when 'rhel', 'amazon'
    package_name node['cfncluster']['kernel_devel_pkg']['name']
    if node['platform'] == 'centos' && node['platform_version'].to_i < 8
      # Do not enforce kernel_devel version on CentOS8 because kernel_devel package with same version as kernel release version cannot be found
      version node['cfncluster']['kernel_devel_pkg']['version']
    end
  when 'debian'
    package_name node['cfncluster']['kernel_generic_pkg']
  end
  retries 3
  retry_delay 5
end

bash "install awscli" do
  cwd Chef::Config[:file_cache_path]
  code <<-CLI
    set -e
    curl --retry 5 --retry-delay 5 "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
    unzip awscli-bundle.zip
    #{node['cfncluster']['cookbook_virtualenv_path']}/bin/python awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
  CLI
  not_if { ::File.exist?("/usr/local/bin/aws") }
end

# Manage SSH via Chef
include_recipe "openssh"

# Install SSH target checker
cookbook_file 'ssh_target_checker.sh' do
  path "/usr/bin/ssh_target_checker.sh"
  owner "root"
  group "root"
  mode "0755"
end

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

if node['platform'] == 'ubuntu' && node['platform_version'].to_f >= 16.04
  # FIXME: https://github.com/atomic-penguin/cookbook-nfs/issues/93
  include_recipe "nfs::server"
end
if node['platform'] == 'centos' && node['platform_version'].to_i == 8
  # Workaround for issue: https://github.com/atomic-penguin/cookbook-nfs/issues/116
  node.force_override['nfs']['service']['idmap'] = 'nfs-idmapd'
end
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
      set -e
      [[ ":$PATH:" != *":/usr/local/bin:"* ]] && PATH="/usr/local/bin:${PATH}"
      echo "PATH is $PATH"
      source #{node['cfncluster']['node_virtualenv_path']}/bin/activate
      pip uninstall --yes aws-parallelcluster-node
      curl --retry 3 -L -o aws-parallelcluster-node.tgz #{node['cfncluster']['custom_node_package']}
      mkdir aws-parallelcluster-custom-node
      tar -xzf aws-parallelcluster-node.tgz --directory aws-parallelcluster-custom-node
      cd aws-parallelcluster-custom-node/*aws-parallelcluster-node-*
      pip install .
      deactivate
    NODE
  end
else
  pyenv_pip 'aws-parallelcluster-node' do
    version node['cfncluster']['cfncluster-node-version']
    virtualenv node['cfncluster']['node_virtualenv_path']
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

# AMI cleanup script
cookbook_file "ami_cleanup.sh" do
  path '/usr/local/sbin/ami_cleanup.sh'
  owner "root"
  group "root"
  mode "0755"
end

# Install Ganglia
include_recipe "aws-parallelcluster::ganglia_install"

# Install NVIDIA and CUDA
include_recipe "aws-parallelcluster::_nvidia_install"

# Install FSx options
include_recipe "aws-parallelcluster::_lustre_install"

# Install EFA & Intel MPI
include_recipe "aws-parallelcluster::efa_install"
include_recipe "aws-parallelcluster::intel_mpi"

# Install the AWS cloudwatch agent
include_recipe "aws-parallelcluster::cloudwatch_agent_install"

# Install Amazon Time Sync
include_recipe "aws-parallelcluster::chrony_install"
