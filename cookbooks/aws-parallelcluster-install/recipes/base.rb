# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: base
#
# Copyright:: 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

include_recipe "aws-parallelcluster::setup_envars"
include_recipe "aws-parallelcluster-install::sudoers"
include_recipe "aws-parallelcluster-install::cluster_admin_user"
include_recipe "aws-parallelcluster-install::disable_services" unless virtualized?

case node['platform_family']
when 'rhel', 'amazon'
  include_recipe 'yum'
  if platform_family?('amazon')
    alinux_extras_topic 'epel'
    # In the case of AL2, there are more packages to install via extras
    node['cluster']['alinux_extras']&.each do |topic|
      alinux_extras_topic topic
    end
  elsif platform?('centos')
    include_recipe "yum-epel"
  end

  # the epel recipe doesn't work on aarch64, needs epel-release package
  package 'epel-release' if node['platform_version'].to_i == 7 && node['kernel']['machine'] == 'aarch64'

  unless node['platform_version'].to_i < 7
    execute 'yum-config-manager_skip_if_unavail' do
      command "yum-config-manager --setopt=\*.skip_if_unavailable=1 --save"
    end
  end

  if platform?('redhat')
    execute 'yum-config-manager-rhel' do
      command "yum-config-manager --enable #{node['cluster']['rhel']['extra_repo']}"
    end
  end
when 'debian'
  apt_update
end

# Setup directories
directory '/etc/parallelcluster'
directory node['cluster']['base_dir']
directory node['cluster']['sources_dir']
directory node['cluster']['scripts_dir']
directory node['cluster']['license_dir']
directory node['cluster']['configs_dir']
directory node['cluster']['shared_dir']

# Create ParallelCluster log folder
directory '/var/log/parallelcluster/' do
  owner 'root'
  mode '1777'
  recursive true
end

build_essential
include_recipe "aws-parallelcluster-install::python"

# Install lots of packages

package node['cluster']['base_packages'] do
  retries 10
  retry_delay 5
  flush_cache({ before: true }) if platform_family?('rhel', 'amazon')
end

unless virtualized?
  package "install kernel packages" do
    case node['platform_family']
    when 'rhel', 'amazon'
      package_name node['cluster']['kernel_devel_pkg']['name']
      version node['cluster']['kernel_devel_pkg']['version']
    when 'debian'
      package_name node['cluster']['kernel_headers_pkg']
    end
    retries 3
    retry_delay 5
  end
end

bash "install awscli" do
  cwd Chef::Config[:file_cache_path]
  code <<-CLI
    set -e
    curl --retry 5 --retry-delay 5 "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
    unzip awscli-bundle.zip
    #{node['cluster']['cookbook_virtualenv_path']}/bin/python awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
  CLI
  not_if { ::File.exist?("/usr/local/bin/aws") }
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
  source 'base/AWS-ParallelCluster-License-README.txt'
  path "#{node['cluster']['license_dir']}/AWS-ParallelCluster-License-README.txt"
  user 'root'
  group 'root'
  mode '0644'
end

# Install NFS packages
if platform?('ubuntu') && node['platform_version'].to_f >= 16.04
  # FIXME: https://github.com/sous-chefs/nfs/issues/93
  include_recipe "nfs::server"
end
include_recipe "nfs::server4"

# Put setup-ephemeral-drives.sh onto the host
cookbook_file 'setup-ephemeral-drives.sh' do
  source 'base/setup-ephemeral-drives.sh'
  path '/usr/local/sbin/setup-ephemeral-drives.sh'
  user 'root'
  group 'root'
  mode '0744'
end

cookbook_file 'setup-ephemeral.service' do
  source 'base/setup-ephemeral.service'
  path '/etc/systemd/system/setup-ephemeral.service'
  owner 'root'
  group 'root'
  mode '0644'
end

include_recipe 'aws-parallelcluster-install::ec2_udev_rules'

# Check whether install a custom aws-parallelcluster-node package or the standard one
if !node['cluster']['custom_node_package'].nil? && !node['cluster']['custom_node_package'].empty?
  # Install custom aws-parallelcluster-node package
  bash "install aws-parallelcluster-node" do
    cwd Chef::Config[:file_cache_path]
    code <<-NODE
      set -e
      [[ ":$PATH:" != *":/usr/local/bin:"* ]] && PATH="/usr/local/bin:${PATH}"
      echo "PATH is $PATH"
      source #{node['cluster']['node_virtualenv_path']}/bin/activate
      pip uninstall --yes aws-parallelcluster-node
      if [[ "#{node['cluster']['custom_node_package']}" =~ ^s3:// ]]; then
        custom_package_url=$(#{node['cluster']['cookbook_virtualenv_path']}/bin/aws s3 presign #{node['cluster']['custom_node_package']} --region #{node['cluster']['region']})
      else
        custom_package_url=#{node['cluster']['custom_node_package']}
      fi
      curl --retry 3 -L -o aws-parallelcluster-node.tgz ${custom_package_url}
      mkdir aws-parallelcluster-custom-node
      tar -xzf aws-parallelcluster-node.tgz --directory aws-parallelcluster-custom-node
      cd aws-parallelcluster-custom-node/*aws-parallelcluster-node-*
      pip install .
      deactivate
    NODE
  end
else
  pyenv_pip 'aws-parallelcluster-node' do
    version node['cluster']['parallelcluster-node-version']
    virtualenv node['cluster']['node_virtualenv_path']
  end
end

# Configure gc_thresh values to be consistent with alinux2 default values for performance at scale
configure_gc_thresh_values

# Put supervisord config in place
cookbook_file "supervisord.conf" do
  source "base/supervisord.conf"
  path "/etc/supervisord.conf"
  owner "root"
  group "root"
  mode "0644"
end

# Put supervisord service in place
template "supervisord-service" do
  source "base/supervisord-service.erb"
  path "/etc/systemd/system/supervisord.service"
  owner "root"
  group "root"
  mode "0644"
end

# AMI cleanup script
cookbook_file "ami_cleanup.sh" do
  source 'base/ami_cleanup.sh'
  path '/usr/local/sbin/ami_cleanup.sh'
  owner "root"
  group "root"
  mode "0755"
end

# Install NVIDIA and CUDA
include_recipe "aws-parallelcluster-install::nvidia"

# Install Neuron driver
include_recipe "aws-parallelcluster-install::neuron" unless virtualized?

# Install EFA & Intel MPI
include_recipe "aws-parallelcluster-install::efa" unless virtualized?
include_recipe "aws-parallelcluster-install::intel_mpi" unless virtualized?

# Install FSx options
include_recipe "aws-parallelcluster-install::lustre"

# Install EFS Utils
include_recipe "aws-parallelcluster-install::efs"

# Install the AWS cloudwatch agent
include_recipe "aws-parallelcluster-install::cloudwatch_agent"

# Configure cron and anacron
include_recipe "aws-parallelcluster-install::cron"

# Install Amazon Time Sync
include_recipe "aws-parallelcluster-install::chrony"

# Install ARM Performance Library
include_recipe "aws-parallelcluster-install::arm_pl"

# Disable x86_64 C states
include_recipe "aws-parallelcluster-install::c_states" unless virtualized?
