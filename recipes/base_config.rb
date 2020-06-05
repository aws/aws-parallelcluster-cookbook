# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: base_config
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

include_recipe 'aws-parallelcluster::base_install'

# Write cloudwatch log config and start it.
include_recipe "aws-parallelcluster::cloudwatch_agent_config"

hostname node['ec2']['local_hostname']
if node['platform_family'] == 'rhel' && node['platform_version'].to_i < 7 || node['platform'] == 'amazon' && node['platform_version'].to_i != 2
  # hostnamectl not present in alinux1 and centos6
  replace_or_add "set hostname in /etc/sysconfig/network" do
    path "/etc/sysconfig/network"
    pattern "HOSTNAME=*"
    line "HOSTNAME=#{node['ec2']['local_hostname'].split('.')[0]}"
  end
  execute "hostname #{node['ec2']['local_hostname'].split('.')[0]}"
else
  execute "hostnamectl set-hostname #{node['ec2']['local_hostname'].split('.')[0]}"
end

# Setup ephemeral drives
execute 'setup ephemeral' do
  command '/usr/local/sbin/setup-ephemeral-drives.sh'
  creates '/scratch'
end

# Amazon Time Sync
include_recipe 'aws-parallelcluster::chrony_config'

# EFA runtime configuration
include_recipe "aws-parallelcluster::efa_config"

# case node['cfncluster']['cfn_node_type']
case node['cfncluster']['cfn_node_type']
when 'MasterServer'
  include_recipe 'aws-parallelcluster::_master_base_config'
when 'ComputeFleet'
  include_recipe 'aws-parallelcluster::_compute_base_config'
else
  raise "cfn_node_type must be MasterServer or ComputeFleet"
end

# Ensure cluster user can sudo on SSH
template '/etc/sudoers.d/99-parallelcluster-user-tty' do
  source '99-parallelcluster-user-tty.erb'
  owner 'root'
  group 'root'
  mode '0600'
end

unless node['cfncluster']['cfn_scheduler'] == 'slurm'
  # Install parallelcluster specific supervisord config
  template '/etc/parallelcluster/parallelcluster_supervisord.conf' do
    source 'parallelcluster_supervisord.conf.erb'
    owner 'root'
    group 'root'
    mode '0644'
  end
end

# Mount EFS directory with efs_mount recipe
include_recipe 'aws-parallelcluster::efs_mount'

# Mount FSx directory with fsx_mount recipe
include_recipe 'aws-parallelcluster::fsx_mount'

# Intel Runtime Libraries
include_recipe "aws-parallelcluster::intel_install"
