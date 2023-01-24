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

include_recipe "aws-parallelcluster-common::setup_envars"
include_recipe "aws-parallelcluster-install::sudo"
include_recipe "aws-parallelcluster-install::users"
include_recipe "aws-parallelcluster-install::disable_services" unless virtualized?

package_repos 'setup the repositories'

include_recipe "aws-parallelcluster-install::directories"

build_essential
include_recipe "aws-parallelcluster-install::python"
include_recipe "aws-parallelcluster-install::cfn_bootstrap"
include_recipe 'aws-parallelcluster-install::node'

install_packages 'Install OS and extra packages'

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

nfs 'install NFS daemon'
include_recipe "aws-parallelcluster-install::ephemeral_drives"
include_recipe 'aws-parallelcluster-install::ec2_udev_rules'

# Configure gc_thresh values to be consistent with alinux2 default values for performance at scale
configure_gc_thresh_values

include_recipe "aws-parallelcluster-install::supervisord"

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
