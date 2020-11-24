# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: prep_env
#
# Copyright 2013-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Validate OS type specified by the user is the same as the OS identified by Ohai
validate_os_type

# Determine cfn_scheduler_slots settings and update cfn_instance_slots appropriately
node.default['cfncluster']['cfn_instance_slots'] = if node['cfncluster']['cfn_scheduler_slots'] == 'vcpus'
                                                     node['cpu']['total']
                                                   elsif node['cfncluster']['cfn_scheduler_slots'] == 'cores'
                                                     node['cpu']['cores']
                                                   else
                                                     node['cfncluster']['cfn_scheduler_slots']
                                                   end
# NOTE: this recipe must be included after cfn_instance_slot because it may alter the values of
#       node['cpu']['total'], which would break the expected behavior when setting cfn_scheduler_slots
#       to one of the constants looked for in the above conditionals
include_recipe "aws-parallelcluster::disable_hyperthreading"

# Setup directories
directory '/etc/parallelcluster'
directory '/opt/parallelcluster'
directory '/opt/parallelcluster/scripts'
directory node['cfncluster']['base_dir']
directory node['cfncluster']['sources_dir']
directory node['cfncluster']['scripts_dir']
directory node['cfncluster']['license_dir']
directory node['cfncluster']['configs_dir']

# Create ParallelCluster log folder
directory '/var/log/parallelcluster/' do
  owner 'root'
  mode '1777'
  recursive true
end

template '/etc/parallelcluster/cfnconfig' do
  source 'cfnconfig.erb'
  mode '0644'
end

link '/opt/parallelcluster/cfnconfig' do
  to '/etc/parallelcluster/cfnconfig'
end

template "/opt/parallelcluster/scripts/fetch_and_run" do
  source 'fetch_and_run.erb'
  owner "root"
  group "root"
  mode "0755"
end

template '/opt/parallelcluster/scripts/compute_ready' do
  source 'compute_ready.erb'
  owner "root"
  group "root"
  mode "0755"
end

include_recipe "aws-parallelcluster::_setup_python"

# Install cloudwatch, write configuration and start it.
include_recipe "aws-parallelcluster::cloudwatch_agent_config"

# Configure additional Networking Interfaces (if present)
include_recipe "aws-parallelcluster::network_interfaces_config"

if node['cfncluster']['cfn_scheduler'] == 'slurm'
  include_recipe "aws-parallelcluster::prep_env_slurm"
end

# Configure hostname and DNS
include_recipe "aws-parallelcluster::dns_config"
