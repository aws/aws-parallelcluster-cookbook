# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-config
# Recipe:: init
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

# Validate OS type specified by the user is the same as the OS identified by Ohai
validate_os_type

# Validate init system
raise "Init package #{node['init_package']} not supported." unless systemd?

include_recipe "aws-parallelcluster-config::cfnconfig_mixed"

template "/opt/parallelcluster/scripts/fetch_and_run" do
  source 'init/fetch_and_run.erb'
  owner "root"
  group "root"
  mode "0755"
end

include_recipe "aws-parallelcluster-config::mount_shared" if node['cluster']['node_type'] == "ComputeFleet"

fetch_config 'Fetch and load cluster configs'

# Install cloudwatch, write configuration and start it.
include_recipe "aws-parallelcluster-config::cloudwatch_agent"

# ParallelCluster log rotation configuration
include_recipe "aws-parallelcluster-config::log_rotation"

# Configure additional Networking Interfaces (if present)
include_recipe "aws-parallelcluster-config::network_interfaces" unless virtualized?

include_recipe "aws-parallelcluster-config::clusterstatusmgtd_init_slurm"

include_recipe "aws-parallelcluster-slurm::init" if node['cluster']['scheduler'] == 'slurm'
include_recipe "aws-parallelcluster-scheduler-plugin::init" if node['cluster']['scheduler'] == 'plugin'

# IMDS
include_recipe 'aws-parallelcluster-config::imds'

# Active Directory Service
include_recipe "aws-parallelcluster-config::directory_service"
